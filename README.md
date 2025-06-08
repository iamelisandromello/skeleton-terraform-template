# 🚀 Terraform AWS Serverless Infrastructure 
### SkeletonPipe

Este projeto provê a infraestrutura automatizada para uma arquitetura **serverless** na AWS utilizando **Terraform**, com suporte completo a **pipelines CI/CD** e **ambientes isolados** por projeto (ex: `dev`, `prod`, `preview`).

---

## 📦 Recursos Provisionados

- 🧠 AWS Lambda
- 🔁 Amazon SQS
- 🔐 IAM Roles & Policies
- 📊 CloudWatch Logs
- 📁 Bucket S3 (referência compartilhada)

---

## 📁 Estrutura de Diretórios

```bash
terraform/
├── main.tf
├── variables.tf
├── outputs.tf
├── locals.tf
├── readme.md
└── modules/
    ├── lambda/
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    ├── iam/
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    ├── cloudwatch/
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    └── sqs/
        ├── main.tf
        ├── variables.tf
        └── outputs.tf
```
---

## 🛠️ Como Usar

### 1. Configuração Inicial

Defina os valores no seu `.tfvars` (ou via pipeline):

```hcl
project_name     = "skeleton"
environment      = "dev"
aws_region       = "us-east-1"
s3_bucket_name   = "bucket-compartilhado"
environments     = { dev = { KEY = "VALUE" } }
global_env_vars  = { STAGE = "dev" }
```

## 🔄 Recursos Dinâmicos

- Recursos são nomeados automaticamente com base em project_name e environment.

- Variáveis de ambiente são mescladas entre globais e específicas por ambiente.

- Suporte à importação condicional para integração com pipelines.

## 📤 CI/CD Sugerido
- Este projeto foi pensado para funcionar com pipelines GitHub Actions ou similares, com etapas para:

- Empacotar código Lambda

- Fazer upload no S3

- Gerar arquivo .tfvars dinâmico

- Executar terraform plan e apply

## 📊 Observabilidade

- Os logs da Lambda são enviados para o CloudWatch Logs.

- Retenção de logs configurada para 14 dias.

- IAM Role da Lambda com permissões mínimas necessárias para log e envio à SQS.

## 👷 Sustentação

- Utilize terraform plan antes de aplicar mudanças.

- Atualize artefatos no S3 com versionamento.

- Mantenha as roles IAM revisadas.

- Adicione alarmes ao CloudWatch, se necessário.

## 📚 Documentação por Módulo

- modules/cloudwatch

- modules/iam

- modules/lambda

- modules/sqs

## 📚 Terraform do Consumidor
- Arquivos Terraform para provisionamento autonomo de recursos na AWS
