import json
import os
import threading
import time
from collections import deque
from queue import Empty, Full, Queue


class TelemetryPipeline:
    """Small 2023-style buffered publisher for bursty mobile telemetry."""

    def __init__(self, queue_depth_metric, publish_latency_metric,
                 published_events_metric, publish_errors_metric, on_event=None):
        self._queue = Queue(maxsize=int(os.getenv('TELEMETRY_QUEUE_SIZE', '100000')))
        self._batch_size = int(os.getenv('TELEMETRY_PUBLISH_BATCH_SIZE', '1000'))
        self._flush_seconds = float(os.getenv('TELEMETRY_FLUSH_SECONDS', '0.1'))
        self._queue_depth_metric = queue_depth_metric
        self._publish_latency_metric = publish_latency_metric
        self._published_events_metric = published_events_metric
        self._publish_errors_metric = publish_errors_metric
        self._on_event = on_event
        self._recent_events = deque(maxlen=int(os.getenv('RECENT_EVENT_BUFFER', '10000')))
        self._publisher = None
        self._topic_path = os.getenv('PUBSUB_TOPIC_PATH', '')
        self.backend_name = 'memory'
        self._enqueue_lock = threading.Lock()

        if self._topic_path:
            from google.cloud import pubsub_v1
            from google.cloud.pubsub_v1.types import BatchSettings

            settings = BatchSettings(
                max_bytes=5 * 1024 * 1024,
                max_latency=self._flush_seconds,
                max_messages=self._batch_size,
            )
            self._publisher = pubsub_v1.PublisherClient(batch_settings=settings)
            self.backend_name = 'pubsub'

        self._worker = threading.Thread(target=self._run, name='telemetry-publisher')
        self._worker.daemon = True
        self._worker.start()

    @property
    def queue_depth(self):
        return self._queue.qsize()

    def enqueue_many(self, events):
        with self._enqueue_lock:
            if self._queue.qsize() + len(events) > self._queue.maxsize:
                return False
            try:
                for event in events:
                    self._queue.put_nowait(event)
            except Full:
                return False
        self._queue_depth_metric.set(self._queue.qsize())
        return True

    def _run(self):
        while True:
            batch = self._next_batch()
            while True:
                started = time.time()
                try:
                    self._publish(batch)
                    self._published_events_metric.labels(backend=self.backend_name).inc(len(batch))
                    break
                except Exception:
                    self._publish_errors_metric.labels(backend=self.backend_name).inc()
                    time.sleep(1)
                finally:
                    self._publish_latency_metric.observe(time.time() - started)
                    self._queue_depth_metric.set(self._queue.qsize())

    def _next_batch(self):
        first = self._queue.get()
        batch = [first]
        deadline = time.time() + self._flush_seconds
        while len(batch) < self._batch_size:
            timeout = deadline - time.time()
            if timeout <= 0:
                break
            try:
                batch.append(self._queue.get(timeout=timeout))
            except Empty:
                break
        return batch

    def _publish(self, batch):
        for event in batch:
            if self._on_event:
                self._on_event(event)
            if self._publisher:
                data = json.dumps(event, separators=(',', ':')).encode('utf-8')
                self._publisher.publish(self._topic_path, data)
            else:
                self._recent_events.append(event)
