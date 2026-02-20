#!/bin/bash
set -e

# 1. GPU VM IP 입력 확인
GPU_VM_IP="${1}"

if [ -z "$GPU_VM_IP" ]; then
  echo "❌ 오류: GPU VM의 IP 주소를 입력해야 합니다."
  echo "👉 사용법: bash setup_monitoring.sh <GPU_VM_IP>"
  echo "👉 예시: bash setup_monitoring.sh 10.0.0.5"
  exit 1
fi

echo "=========================================="
echo "📊 LLM 모니터링 스택 (Prometheus + Grafana) 설치"
echo "타겟 GPU VM IP: $GPU_VM_IP"
echo "=========================================="

# 2. Docker 및 Docker Compose 설치 확인
echo "Checking for Docker..."
if ! command -v docker >/dev/null 2>&1; then
  echo "Docker가 설치되어 있지 않습니다. 자동 설치를 시작합니다..."
  curl -fsSL https://get.docker.com -o get-docker.sh
  sudo sh get-docker.sh
  sudo apt-get install -y docker-compose-plugin
else
  echo "✅ Docker가 이미 설치되어 있습니다."
fi

# 3. 작업 폴더 생성
WORK_DIR="$HOME/llm_monitor"
mkdir -p "$WORK_DIR"
cd "$WORK_DIR"
echo "작업 디렉토리: $WORK_DIR"

# 4. prometheus.yml 파일 자동 생성
echo "설정 파일(prometheus.yml)을 생성합니다..."
cat <<EOF > prometheus.yml
global:
  scrape_interval: 5s # 5초마다 데이터 수집

scrape_configs:
  # GPU 센서 (전력, 온도, VRAM 등)
  - job_name: 'amdgpu'
    static_configs:
      - targets: ['${GPU_VM_IP}:9101']

  # vLLM 센서 (TPS, Latency, 큐 사이즈 등)
  - job_name: 'vllm'
    static_configs:
      - targets: ['${GPU_VM_IP}:8000']
EOF

# 5. docker-compose.yml 파일 자동 생성
echo "설정 파일(docker-compose.yml)을 생성합니다..."
cat <<EOF > docker-compose.yml
version: '3.8'
services:
  prometheus:
    image: prom/prometheus:latest
    container_name: prometheus
    ports:
      - "9090:9090"
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml
    restart: always

  grafana:
    image: grafana/grafana:latest
    container_name: grafana
    ports:
      - "3000:3000"
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=admin # 초기 비밀번호 설정
    restart: always
EOF

# 6. Docker Compose로 모니터링 스택 백그라운드 실행
echo "🚀 Prometheus와 Grafana 컨테이너를 시작합니다..."
sudo docker compose up -d

echo ""
echo "=========================================="
echo "🎉 모든 설치 및 실행이 성공적으로 완료되었습니다!"
echo "=========================================="
echo "🌐 [1] Prometheus 연결 상태 확인 (Target UP 확인 필수):"
echo "    -> http://<이_관리VM의_공인IP>:9090/targets"
echo ""
echo "📈 [2] Grafana 대시보드 접속:"
echo "    -> http://<이_관리VM의_공인IP>:3000"
echo "    -> 초기 로그인 ID: admin / PW: admin"
echo "=========================================="