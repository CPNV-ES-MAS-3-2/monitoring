# Infrastructure

## Instances
### Ressources
- Quantité : x1
- OS : Ubuntu 24.04 LTS
- CPU : 2
- RAM : 4 GB
- Disk 1 : 20 GB
- Disk 2 : 50 GB

### Ports d'accès

| Port | Protocole | Usage |
|------|-----------|-------|
| 22 | TCP | SSH |
| 80 | TCP | HTTP Reverse-Proxy |

## Architecture
!["Architecture"](/.github/img/arch_scheme.png)

## Structure des fichiers
```
.
├── .github/
│   ├── diagrams/          # diagrams code
│   ├── img/               # images for README              
├── nodes/                 # Client-side agent configs
│   ├── k8s/               # K8s configs + Detailed README
│   ├── docker/            # Docker configs + Detailed README
│   └── linux/             # Linux configs + Detailed README
├── server/                # Monitoring server configs + Detailed README       
├── ANALYSIS.md            # Analysis for monitoring stack choice
└── README.md              # Root README.md
```