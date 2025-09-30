# Service Level Objectives (SLOs) for DumbKV

This document describes the recommended Service Level Objectives for the DumbKV application based on its architecture, limitations, and available metrics.

## Availability SLO

**Target: 99.0% (3 nines)**

**Reasoning:** This is a simple demonstration KV store with known stability issues (easy to DoS, poor storage). 99.0% allows ~7 hours of downtime per month, which is reasonable for a non-critical service.

**Measurement:** `(successful requests / total requests) >= 0.99` where successful = HTTP status 2xx/3xx

**Prometheus Query:**
```promql
sum(rate(http_requests_total{status=~"2xx|3xx"}[5m]))
/
sum(rate(http_requests_total[5m])) >= 0.99
```

## Latency SLO

**Target: 95% of requests < 500ms**

**Reasoning:** Key-value operations should be fast. The app performs hash computations and encryption/decryption, which adds overhead. 500ms at p95 provides buffer for database operations while maintaining acceptable user experience.

**Measurement:** `http_request_duration_highr_seconds` histogram p95 bucket

**Prometheus Query:**
```promql
histogram_quantile(0.95, sum(rate(http_request_duration_highr_seconds_bucket[5m])) by (le)) < 0.5
```

## Error Rate SLO

**Target: < 1% error rate**

**Reasoning:** Given the application's simplicity and lack of robust error handling, a 1% error budget is realistic while still maintaining quality.

**Measurement:** `(5xx responses / total requests) < 0.01`

**Prometheus Query:**
```promql
sum(rate(http_requests_total{status="5xx"}[5m]))
/
sum(rate(http_requests_total[5m])) < 0.01
```

## Additional Considerations

### Architecture Limitations

- **SQLite backend:** Single replica with SQLite has no redundancy, making high availability impossible
- **PostgreSQL backend:** Enables better availability through connection pooling and potential for multiple replicas
- **Known issues:** Application documentation states it "doesn't do a lot of checks so it's very easy to DoS" - this limits realistic availability targets

### Monitoring Recommendations

1. **Alert on SLO Burns:** Configure alerts when error budget consumption exceeds expected burn rate
2. **Dashboard:** Create Grafana dashboard tracking all three SLOs with historical trends
3. **Review Cadence:** Review SLOs monthly and adjust based on actual usage patterns and business requirements

### Future Improvements

As the application matures, consider:
- Increasing availability target to 99.5% with improved error handling
- Adding separate SLOs for read vs write operations
- Implementing rate limiting to prevent DoS attacks
- Adding durability guarantees for the PostgreSQL backend