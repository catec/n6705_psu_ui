# UML and System Diagrams

Author: Mouhsine Kassimi Farhaoui  
Mail: mouhsine98@gmail.com

## Architecture Component Diagram

```mermaid
flowchart LR
  UI[QML UI\nMain + Views + Components] --> VM[ViewModels\nDashboard/Channel]
  VM --> DEV[Device Adapter\nN6705PowerAnalyzer]
  DEV --> SCPI[SCPI Transport\nScpiTcpClient]
  SCPI --> PSU[Keysight N6705]
  VM --> LOG[CSV Logger]
  LOG --> CSV[(CSV Files)]
  VM --> HIST[Historical Loader]
  HIST --> CSV
  VM --> JSON[(session.json)]
```

## Core Class Diagram

```mermaid
classDiagram
  class ScpiTcpClient {
    +connect()
    +disconnect()
    +write(command)
    +query(command)
  }

  class N6705PowerAnalyzer {
    +identify()
    +measure_channels(channels)
    +set_voltage(channel, voltage)
    +set_current(channel, current)
    +set_output(channel, enabled)
  }

  class DashboardViewModel {
    +connectDevice()
    +startMonitoring()
    +startLogging()
    +loadLogFiles(paths)
  }

  class ChannelViewModel
  class ConsumptionLogger
  class LogPlotLoader

  DashboardViewModel --> N6705PowerAnalyzer
  N6705PowerAnalyzer --> ScpiTcpClient
  DashboardViewModel --> ChannelViewModel
  DashboardViewModel --> ConsumptionLogger
  DashboardViewModel --> LogPlotLoader
```

## Runtime Sequence (Simplified)

```mermaid
sequenceDiagram
  actor User
  participant QML as Main.qml
  participant VM as DashboardViewModel
  participant Driver as N6705PowerAnalyzer
  participant TCP as ScpiTcpClient
  participant Logger as ConsumptionLogger

  User->>QML: Connect + Run
  QML->>VM: connectDevice(...)
  VM->>Driver: connect()
  Driver->>TCP: query(*IDN?)
  TCP-->>Driver: IDN
  Driver-->>VM: connected
  VM-->>QML: connectionChanged

  loop polling interval
    VM->>Driver: measure_channels(...)
    Driver->>TCP: SCPI queries
    TCP-->>Driver: sample values
    Driver-->>VM: samples
    VM-->>QML: telemetryChanged
    alt logging active
      VM->>Logger: register(sample)
    end
  end
```

## PlantUML Source Files

- `docs/doxygen/uml/class_diagram.puml`
- `docs/doxygen/uml/runtime_sequence.puml`
- `docs/doxygen/uml/component_view.puml`
