import unittest
from unittest.mock import patch

from app import app
from sql_generator import SQLGenerator, SQLGeneratorError


VALID_EVENT = {
    'ip-address': '10.0.0.1',
    'device_information': {
        'device_info': {'model': 'Pixel', 'android': '13', 'hardware': 'board'},
        'location': {'latitude': 41.88, 'longitude': -87.63, 'altitude': 181, 'accuracy': 3},
        'timestamp': '2023-08-01T12:00:00Z',
    },
    'lte_params': {
        'mcc': '310', 'mnc': '260', 'band': '48', 'Fc': 3550.0,
        'EarFcn': 55240, 'TimeAdv': 1, 'tac': '1', 'eci': '1',
        'pci': 10, 'rsrp': -85.0, 'rsrq': -9.0, 'rssi': -65.0,
        'snr': 20.0, 'cqi': 12,
    },
}


class AppTest(unittest.TestCase):
    def setUp(self):
        self.client = app.test_client()

    def test_accepts_one_event(self):
        response = self.client.post('/data', json=VALID_EVENT)
        self.assertEqual(response.status_code, 202)
        self.assertEqual(response.get_json()['accepted'], 1)

    def test_rejects_invalid_event(self):
        response = self.client.post('/data', json={'ip-address': 'bad'})
        self.assertEqual(response.status_code, 400)

    def test_accepts_batch(self):
        response = self.client.post('/data/batch', json=[VALID_EVENT] * 10)
        self.assertEqual(response.status_code, 202)
        self.assertEqual(response.get_json()['accepted'], 10)


class SQLGeneratorTest(unittest.TestCase):
    def test_rejects_write_statement(self):
        with self.assertRaises(SQLGeneratorError):
            SQLGenerator._clean_and_validate('DELETE FROM telemetry.events')

    def test_rejects_other_tables(self):
        with self.assertRaises(SQLGeneratorError):
            SQLGenerator._clean_and_validate(
                'SELECT * FROM private.users JOIN telemetry.events ON TRUE LIMIT 10'
            )

    def test_caps_result_limit(self):
        sql = SQLGenerator._clean_and_validate(
            'SELECT band FROM telemetry.events LIMIT 10000'
        )
        self.assertTrue(sql.endswith('LIMIT 1000'))

    @patch.dict('os.environ', {'OPENAI_API_KEY': 'test'})
    @patch('openai.ChatCompletion.create')
    def test_caches_generated_sql(self, create):
        create.return_value = {
            'choices': [{'message': {'content': 'SELECT band FROM telemetry.events LIMIT 10'}}]
        }
        generator = SQLGenerator()
        first, first_hit = generator.generate('show bands')
        second, second_hit = generator.generate('show bands')
        self.assertEqual(first, second)
        self.assertFalse(first_hit)
        self.assertTrue(second_hit)
        create.assert_called_once()


if __name__ == '__main__':
    unittest.main()
