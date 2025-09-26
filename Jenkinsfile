pipeline {
    agent any

    environment {
        REMOTE_PATH = "/home/ubuntu/ci-cd"
        DOCKER_IMAGE = "kiritokazut0/ci-cd:latest"
    }

    parameters {
        string(name: 'EC2_HOST', defaultValue: '', description: 'IP o hostname de tu EC2')
        string(name: 'CREDENTIAL_ID', defaultValue: '', description: 'ID de las credenciales SSH en Jenkins')
    }

    stages {
        stage('Checkout del código') {
            steps {
                git branch: 'develop', url: 'https://github.com/KiritoKazut0/ci-cd.git'
            }
        }

        stage('Build y push Docker') {
            steps {
                sh """
                    echo "Construyendo imagen Docker..."
                    docker build -t $DOCKER_IMAGE .
                    echo "Subiendo imagen a Docker Hub..."
                    docker push $DOCKER_IMAGE
                """
            }
        }

        stage('Despliegue en EC2') {
            steps {
                withCredentials([sshUserPrivateKey(
                    credentialsId: params.CREDENTIAL_ID,
                    keyFileVariable: 'SSH_KEY_FILE',
                    usernameVariable: 'EC2_USER'
                )]) {
                    sh """
                        chmod 600 "$SSH_KEY_FILE"

                        ssh -o StrictHostKeyChecking=no -i "$SSH_KEY_FILE" $EC2_USER@${params.EC2_HOST} 'bash -s' <<'ENDSSH'
                        echo "Conexión exitosa a EC2"

                        # 1️⃣ Verificar Docker
                        if ! command -v docker &> /dev/null; then
                            echo "Docker no encontrado, instalando versión oficial..."
                            sudo apt-get update
                            sudo apt-get install -y ca-certificates curl
                            sudo install -m 0755 -d /etc/apt/keyrings
                            sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
                            sudo chmod a+r /etc/apt/keyrings/docker.asc
                            echo "deb [arch=\$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \$(. /etc/os-release && echo \${UBUNTU_CODENAME:-\$VERSION_CODENAME}) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
                            sudo apt-get update
                            sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
                            sudo systemctl start docker
                            sudo systemctl enable docker
                        else
                            echo "Docker ya está instalado"
                        fi

                        # 2️⃣ Verificar Nginx
                        if ! command -v nginx &> /dev/null; then
                            echo "Nginx no encontrado, instalando..."
                            sudo apt-get install -y nginx
                            sudo systemctl start nginx
                            sudo systemctl enable nginx
                        else
                            echo "Nginx ya está instalado"
                        fi

                        # 3️⃣ Configurar Nginx
                        sudo tee /etc/nginx/sites-available/ci-cd > /dev/null <<'EOF'
                        server {
                            listen 80;
                            server_name _;

                            location / {
                                proxy_pass http://localhost:3000;
                                proxy_set_header Host \$host;
                                proxy_set_header X-Real-IP \$remote_addr;
                                proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
                            }
                        }
                        EOF

                        sudo ln -sf /etc/nginx/sites-available/ci-cd /etc/nginx/sites-enabled/ci-cd
                        sudo nginx -t && sudo systemctl reload nginx

                        # 4️⃣ Desplegar aplicación
                        if [ \$(docker ps -q -f name=ci-cd) ]; then
                            docker stop ci-cd
                            docker rm ci-cd
                        fi

                        docker pull kiritokazut0/ci-cd:latest
                        docker run -d --name ci-cd -p 3000:3000 kiritokazut0/ci-cd:latest
                        ENDSSH
                    """
                }
            }
        }
    }

    post {
        success {
            echo '✅ CI/CD completo: código actualizado, imagen Docker subida y desplegada en EC2!'
        }
        failure {
            echo '❌ Error en el pipeline!'
        }
    }
}
