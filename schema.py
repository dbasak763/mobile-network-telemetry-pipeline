schema = {
    "type": "object",
    "properties": {
        "device_information": {
            "type": "object",
            "properties": {
                "device_info": {
                    "type": "object",
                    "properties": {
                        "model": {"type": "string"},
                        "android": {"type": "string"},
                        "hardware": {"type": "string"}
                    },
                    "required": ["model", "android", "hardware"]
                },
                "location": {
                    "type": "object",
                    "properties": {
                        "latitude": {"type": "number"},
                        "longitude": {"type": "number"},
                        "altitude": {"type": "number"},
                        "accuracy": {"type": "number"}
                    },
                    "required": ["latitude", "longitude", "altitude", "accuracy"]
                },
                "ipaddress": {"type": "string", "format": "ipv4"},
                "timestamp": {"type": "string", "format": "date-time"}
            },
            "required": ["device_info", "location", "ipaddress", "timestamp"]
        },
        "lte_params": {
            "type": "object",
            "properties": {
                "mcc": {"type": "string"},
                "mnc": {"type": "string"},
                "band": {"type": "string"},
                "Fc": {"type": "number"},
                "EarFcn": {"type": "number"},
                "TimeAdv": {"type": "number"},
                "tac": {"type": "string"},
                "eci": {"type": "string"},
                "pci": {"type": "number"},
                "rsrp": {"type": "number"},
                "rsrq": {"type": "number"},
                "rssi": {"type": "number"},
                "snr": {"type": "number"},
                "cqi": {"type": "number"}
            },
            "required": ["mcc", "mnc", "band", "Fc", "EarFcn", "TimeAdv", "tac", "eci", "pci", "rsrp", "rsrq", "rssi", "snr", "cqi"]
        }
    },
    "required": ["device_information", "lte_params"]
}

