### 📄 `modules/cloudwatch/README.md`

```markdown
# 📊 CloudWatch Log Group Module

Este módulo cria um grupo de logs no AWS CloudWatch para uso com funções Lambda.

---

## Recursos Criados

- `aws_cloudwatch_log_group`

---

## Entradas

| Nome            | Tipo     | Descrição                             |
|-----------------|----------|----------------------------------------|
| `log_group_name` | `string` | Nome do grupo de logs (geralmente baseado no nome da Lambda) |

---

## Comportamento

- A retenção de logs é de 14 dias.
- `prevent_destroy = true` impede exclusão acidental via Terraform.

---

## Exemplo de Uso

```hcl
module "cloudwatch" {
  source         = "../cloudwatch"
  log_group_name = "/aws/lambda/my-lambda-dev"
}
