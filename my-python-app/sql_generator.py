import os
import re
import threading

from cachetools import TTLCache


class SQLGeneratorError(Exception):
    pass


class SQLGenerator:
    """Generate read-only BigQuery SQL with the OpenAI API available in 2023."""

    SYSTEM_PROMPT = """You translate analytics questions into BigQuery Standard SQL.
Return SQL only. Use only telemetry.events with these fields:
event_timestamp TIMESTAMP, ip_address STRING, model STRING, android STRING,
latitude FLOAT64, longitude FLOAT64, altitude FLOAT64, accuracy FLOAT64,
mcc STRING, mnc STRING, band STRING, fc FLOAT64, earfcn INT64,
timing_advance INT64, tac STRING, eci STRING, pci INT64, rsrp FLOAT64,
rsrq FLOAT64, rssi FLOAT64, snr FLOAT64, cqi INT64.
Generate one read-only SELECT statement, always include a LIMIT no greater than 1000,
and use TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL ... ) for relative time windows."""

    def __init__(self):
        self._cache = TTLCache(
            maxsize=int(os.getenv('SQL_CACHE_SIZE', '512')),
            ttl=int(os.getenv('SQL_CACHE_TTL_SECONDS', '3600')),
        )
        self._lock = threading.Lock()

    def generate(self, question):
        key = ' '.join(question.lower().split())
        with self._lock:
            cached = self._cache.get(key)
        if cached:
            return cached, True

        if not os.getenv('OPENAI_API_KEY'):
            raise SQLGeneratorError('OPENAI_API_KEY is not configured')

        try:
            import openai
            response = openai.ChatCompletion.create(
                model=os.getenv('OPENAI_MODEL', 'gpt-3.5-turbo-0613'),
                temperature=0,
                messages=[
                    {'role': 'system', 'content': self.SYSTEM_PROMPT},
                    {'role': 'user', 'content': question},
                ],
            )
            sql = response['choices'][0]['message']['content']
        except Exception as error:
            raise SQLGeneratorError('SQL generation failed: {}'.format(error))

        sql = self._clean_and_validate(sql)
        with self._lock:
            self._cache[key] = sql
        return sql, False

    @staticmethod
    def _clean_and_validate(sql):
        sql = re.sub(r'^```(?:sql)?\s*|\s*```$', '', sql.strip(), flags=re.I)
        normalized = ' '.join(sql.split())
        banned = r'\b(INSERT|UPDATE|DELETE|DROP|ALTER|CREATE|MERGE|GRANT|REVOKE|CALL)\b'
        if not re.match(r'^SELECT\b', normalized, re.I):
            raise SQLGeneratorError('Model did not return a read-only query')
        if re.search(banned, normalized, re.I) or normalized.rstrip(';').count(';'):
            raise SQLGeneratorError('Generated SQL contains a disallowed statement')
        if not re.search(r'\btelemetry\.events\b', normalized, re.I):
            raise SQLGeneratorError('Generated SQL does not use telemetry.events')
        tables = re.findall(
            r'\b(?:FROM|JOIN)\s+`?([A-Za-z0-9_.-]+)`?', normalized, re.I
        )
        if not tables or any(table.lower() != 'telemetry.events' for table in tables):
            raise SQLGeneratorError('Generated SQL references a disallowed table')
        limit = re.search(r'\bLIMIT\s+(\d+)\b', normalized, re.I)
        if not limit:
            normalized = '{} LIMIT 1000'.format(normalized.rstrip(';'))
        elif int(limit.group(1)) > 1000:
            normalized = '{} LIMIT 1000{}'.format(
                normalized[:limit.start()].rstrip(),
                normalized[limit.end():],
            )
        return normalized.rstrip(';')
