
---

### 📄 `modules/lambda/README.md`

```markdown
# 🧠 Lambda Function Module

Este módulo provisiona uma função AWS Lambda com variáveis de ambiente e código armazenado em um bucket S3.

---

## Recursos Criados

- `aws_lambda_function`

---

## Entradas

| Nome                   | Tipo     | Descrição                                     |
|------------------------|----------|-----------------------------------------------|
| `lambda_name`           | `string` | Nome da função Lambda                         |
| `role_arn`              | `string` | IAM Role ARN atribuído à Lambda               |
| `s3_bucket`             | `string` | Nome do bucket S3 contendo o código ZIP       |
| `s3_key`                | `string` | Caminho/arquivo ZIP dentro do bucket          |
| `handler`               | `string` | Ex: `main/app.handler`                        |
| `runtime`               | `string` | Ex: `nodejs20.x`, `python3.11`                |
| `environment_variables` | `map`    | Mapa de variáveis de ambiente da função       |

---

## Saídas

| Nome                  | Tipo     | Descrição                        |
|-----------------------|----------|-----------------------------------|
| `lambda_function_name` | `string` | Nome da função Lambda             |
| `lambda_arn`           | `string` | ARN da função Lambda              |

---

## Exemplo de Uso

```hcl
module "lambda" {
  source                = "../lambda"
  lambda_name           = "my-lambda-dev"
  role_arn              = module.iam.role_arn
  s3_bucket             = "bucket-compartilhado"
  s3_key                = "my-lambda-dev.zip"
  handler               = "main/app.handler"
  runtime               = "nodejs20.x"
  environment_variables = local.environment_variables
}
