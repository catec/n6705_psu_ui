# Architecture Reference

Author: Mouhsine Kassimi Farhaoui  
Mail: mouhsine98@gmail.com

## Layered Architecture

The project follows MVVM + Ports/Adapters:

- Presentation: QML views and reusable components
- ViewModel: UI orchestration and reactive state
- Domain models: typed telemetry and cumulative totals
- Adapters: SCPI transport and N6705 command adapter
- Services: CSV logging and historical plot loading

## Runtime Data Flow

1. QML triggers a ViewModel slot.
2. DashboardViewModel delegates to N6705PowerAnalyzer.
3. N6705PowerAnalyzer issues SCPI commands via ScpiTcpClient.
4. Polling thread emits samples to the UI thread.
5. ViewModels update charts, totals, and event log.
6. Optional logging persists samples to CSV.

## Reliability Notes

- Batch measurement with automatic per-channel fallback
- Polling stop policy after consecutive acquisition failures
- Session persistence to JSON for deterministic startup
- Input validation for host/port/timeout and polling rates
