"""Genere par retrain.py - NE PAS EDITER A LA MAIN. Aucune dependance."""

def predict_irrigation(soil_raw, air_temp, air_hum, light, water_dist):
    if water_dist <= 9.9650:
        if soil_raw <= 613.5900:
            if soil_raw <= 581.2250:
                if water_dist <= 9.7350:
                    if soil_raw <= 559.0450:
                        if water_dist <= 9.6700:
                            return 'OFF'
                        else:
                            return 'OFF'
                    else:
                        if light <= 30511.9746:
                            return 'OFF'
                        else:
                            return 'IRRIGATE'
                else:
                    if soil_raw <= 499.0200:
                        if light <= 13653.7798:
                            return 'OFF'
                        else:
                            return 'OFF'
                    else:
                        return 'REFILL_ALERT'
            else:
                if light <= 19950.0752:
                    if air_hum <= 81.8600:
                        if soil_raw <= 601.7000:
                            return 'OFF'
                        else:
                            return 'IRRIGATE'
                    else:
                        if air_hum <= 86.4500:
                            return 'OFF'
                        else:
                            return 'OFF'
                else:
                    if light <= 29181.2305:
                        if air_temp <= 25.9300:
                            return 'OFF'
                        else:
                            return 'IRRIGATE'
                    else:
                        if soil_raw <= 598.5950:
                            return 'IRRIGATE'
                        else:
                            return 'IRRIGATE'
        else:
            if soil_raw <= 642.9700:
                if air_hum <= 83.3950:
                    if soil_raw <= 616.4500:
                        return 'IRRIGATE'
                    else:
                        return 'IRRIGATE'
                else:
                    if air_temp <= 20.5850:
                        if soil_raw <= 630.8050:
                            return 'OFF'
                        else:
                            return 'OFF'
                    else:
                        return 'IRRIGATE'
            else:
                if water_dist <= 9.7650:
                    if soil_raw <= 653.0750:
                        if air_hum <= 86.7650:
                            return 'IRRIGATE'
                        else:
                            return 'IRRIGATE'
                    else:
                        if soil_raw <= 660.1850:
                            return 'IRRIGATE'
                        else:
                            return 'IRRIGATE'
                else:
                    if light <= 6821.1902:
                        if air_hum <= 89.4050:
                            return 'IRRIGATE'
                        else:
                            return 'IRRIGATE'
                    else:
                        return 'IRRIGATE'
    else:
        if water_dist <= 10.2050:
            if soil_raw <= 716.2450:
                if soil_raw <= 586.1100:
                    if water_dist <= 10.0450:
                        if air_hum <= 86.1900:
                            return 'REFILL_ALERT'
                        else:
                            return 'OFF'
                    else:
                        if light <= 6853.4851:
                            return 'REFILL_ALERT'
                        else:
                            return 'REFILL_ALERT'
                else:
                    if air_hum <= 78.5750:
                        return 'REFILL_ALERT'
                    else:
                        return 'REFILL_ALERT'
            else:
                if water_dist <= 10.0550:
                    return 'IRRIGATE'
                else:
                    if air_hum <= 82.2950:
                        return 'REFILL_ALERT'
                    else:
                        return 'REFILL_ALERT'
        else:
            if water_dist <= 10.2550:
                if soil_raw <= 663.4100:
                    return 'REFILL_ALERT'
                else:
                    return 'REFILL_ALERT'
            else:
                if water_dist <= 10.4550:
                    if soil_raw <= 487.6650:
                        if air_temp <= 22.3800:
                            return 'REFILL_ALERT'
                        else:
                            return 'REFILL_ALERT'
                    else:
                        if soil_raw <= 786.2550:
                            return 'REFILL_ALERT'
                        else:
                            return 'REFILL_ALERT'
                else:
                    return 'REFILL_ALERT'

def predict_climate(air_temp, air_hum, light):
    if air_hum <= 90.1500:
        if air_temp <= 28.6550:
            if air_hum <= 87.8150:
                if air_temp <= 27.3850:
                    if air_hum <= 86.7550:
                        if air_temp <= 27.0350:
                            return 'FAN_OFF'
                        else:
                            return 'FAN_OFF'
                    else:
                        if light <= 1025.1050:
                            return 'FAN_OFF'
                        else:
                            return 'FAN_OFF'
                else:
                    if light <= 29476.4844:
                        if air_hum <= 78.9050:
                            return 'FAN_OFF'
                        else:
                            return 'FAN_ON'
                    else:
                        if air_temp <= 27.9950:
                            return 'FAN_ON'
                        else:
                            return 'FAN_ON'
            else:
                if air_hum <= 89.4450:
                    if air_hum <= 88.2550:
                        if air_hum <= 87.9050:
                            return 'FAN_OFF'
                        else:
                            return 'FAN_OFF'
                    else:
                        if air_hum <= 88.3550:
                            return 'FAN_ON'
                        else:
                            return 'FAN_OFF'
                else:
                    if light <= 19.9100:
                        if air_hum <= 89.7800:
                            return 'FAN_OFF'
                        else:
                            return 'FAN_ON'
                    else:
                        if air_hum <= 89.8050:
                            return 'FAN_OFF'
                        else:
                            return 'FAN_OFF'
        else:
            if air_temp <= 30.1750:
                if light <= 29292.1797:
                    if air_hum <= 79.2950:
                        if air_temp <= 29.6000:
                            return 'FAN_OFF'
                        else:
                            return 'FAN_OFF'
                    else:
                        return 'FAN_ON'
                else:
                    if light <= 31046.9854:
                        return 'FAN_ON'
                    else:
                        if light <= 48322.8359:
                            return 'FAN_ON'
                        else:
                            return 'FAN_ON'
            else:
                if air_temp <= 30.6350:
                    if light <= 28855.6602:
                        if air_temp <= 30.4150:
                            return 'FAN_ON'
                        else:
                            return 'FAN_ON'
                    else:
                        return 'FAN_ON'
                else:
                    if light <= 10121.7646:
                        return 'FAN_ON'
                    else:
                        return 'FAN_ON'
    else:
        if air_hum <= 92.1050:
            if air_temp <= 18.3150:
                if air_hum <= 90.6350:
                    if air_hum <= 90.3550:
                        return 'FAN_ON'
                    else:
                        if light <= 23.4150:
                            return 'FAN_ON'
                        else:
                            return 'FAN_ON'
                else:
                    if light <= 10.6650:
                        if light <= 3.8450:
                            return 'FAN_ON'
                        else:
                            return 'FAN_ON'
                    else:
                        if air_temp <= 16.5200:
                            return 'FAN_ON'
                        else:
                            return 'FAN_ON'
            else:
                if air_hum <= 90.7950:
                    if light <= 26.7750:
                        return 'FAN_ON'
                    else:
                        if light <= 11330.9497:
                            return 'FAN_OFF'
                        else:
                            return 'FAN_OFF'
                else:
                    if light <= 12638.2202:
                        if air_temp <= 21.8450:
                            return 'FAN_ON'
                        else:
                            return 'FAN_ON'
                    else:
                        return 'FAN_ON'
        else:
            if air_hum <= 93.2550:
                if air_temp <= 20.3100:
                    if air_hum <= 92.7050:
                        if air_hum <= 92.4700:
                            return 'FAN_ON'
                        else:
                            return 'FAN_ON'
                    else:
                        if air_hum <= 92.8950:
                            return 'FAN_ON'
                        else:
                            return 'FAN_ON'
                else:
                    if air_temp <= 21.9350:
                        return 'FAN_ON'
                    else:
                        return 'FAN_ON'
            else:
                if air_hum <= 94.2450:
                    if air_temp <= 16.7100:
                        return 'FAN_ON'
                    else:
                        if air_temp <= 19.6150:
                            return 'FAN_ON'
                        else:
                            return 'FAN_ON'
                else:
                    if light <= 1.3450:
                        if light <= 0.8050:
                            return 'FAN_ON'
                        else:
                            return 'FAN_ON'
                    else:
                        if air_temp <= 24.5600:
                            return 'FAN_ON'
                        else:
                            return 'FAN_ON'

def predict_anomaly(soil_before, soil_drop, water_drop_cm, soil_std):
    if soil_std <= 19.6750:
        if soil_drop <= 94.7750:
            if water_drop_cm <= 0.5200:
                return 'POMPE_BLOQUEE'
            else:
                if soil_before <= 595.5350:
                    return 'FUITE'
                else:
                    return 'FUITE'
        else:
            return 'NORMAL'
    else:
        return 'CAPTEUR_DEFAILLANT'
