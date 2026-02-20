import time
import subprocess
import json
from prometheus_client import start_http_server, Gauge

# how to run:
# sudo apt-get install -y python3-pip
# pip3 install prometheus_client
# nohup python3 rocm_exporter.py > exporter.log 2>&1 &

g_temp = Gauge('amdgpu_temperature_edge', 'GPU Temperature (C)', ['gpu_id'])
g_power = Gauge('amdgpu_power_draw_watts', 'GPU Power Draw (W)', ['gpu_id'])
g_vram = Gauge('amdgpu_vram_usage_percent', 'VRAM Usage (%)', ['gpu_id'])
g_util = Gauge('amdgpu_utilization_percent', 'GPU Utilization (%)', ['gpu_id'])

def collect_metrics():
    try:
        result = subprocess.check_output(['rocm-smi', '-a', '--json'], text=True)
        data = json.loads(result)

        for gpu_key, metrics in data.items():
            if not gpu_key.startswith("card"):
                continue

            gpu_id = gpu_key

            if "Temperature (Sensor edge) (C)" in metrics:
                g_temp.labels(gpu_id=gpu_id).set(float(metrics["Temperature (Sensor edge) (C)"]))

            if "Average Graphics Package Power (W)" in metrics:
                g_power.labels(gpu_id=gpu_id).set(float(metrics["Average Graphics Package Power (W)"]))

            if "GPU Memory Allocated (VRAM%)" in metrics:
                g_vram.labels(gpu_id=gpu_id).set(float(metrics["GPU Memory Allocated (VRAM%)"]))

            if "GPU use (%)" in metrics:
                g_util.labels(gpu_id=gpu_id).set(float(metrics["GPU use (%)"]))

    except Exception as e:
        print(f"데이터 수집 에러: {e}")

if __name__ == '__main__':
    print("🚀 ROCm Exporter가 9101 포트에서 실행 중입니다...")
    start_http_server(9101)

    while True:
        collect_metrics()
        time.sleep(2)