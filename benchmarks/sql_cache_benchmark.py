import argparse
import json
import statistics
import time
from urllib.request import Request, urlopen


QUESTIONS = [
    'average RSRP by band over the last 15 minutes',
    'five cells with the lowest average SNR in the last hour',
    'count devices by Android version today',
    'average timing advance by MCC and MNC in the last 30 minutes',
]


def request_sql(base_url, question):
    body = json.dumps({'question': question}).encode('utf-8')
    request = Request(
        base_url.rstrip('/') + '/query/sql',
        data=body,
        headers={'Content-Type': 'application/json'},
    )
    started = time.perf_counter()
    with urlopen(request) as response:
        json.load(response)
    return time.perf_counter() - started


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--base-url', default='http://localhost:5050')
    args = parser.parse_args()

    cold = [request_sql(args.base_url, question) for question in QUESTIONS]
    warm = [request_sql(args.base_url, question) for question in QUESTIONS]
    cold_median = statistics.median(cold)
    warm_median = statistics.median(warm)
    reduction = (cold_median - warm_median) / cold_median * 100

    print('cold median: {:.3f}s'.format(cold_median))
    print('warm median: {:.3f}s'.format(warm_median))
    print('latency reduction: {:.1f}%'.format(reduction))
    if reduction < 87:
        raise SystemExit('Expected at least an 87% cached-latency reduction')


if __name__ == '__main__':
    main()
