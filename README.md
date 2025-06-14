# 🚀 Módulo Terraform: AWS Lambda e SQS Deployment

Este repositório fornece um **módulo Terraform reutilizável** para implantar uma função AWS Lambda completa, juntamente com todos os seus componentes de infraestrutura necessários: papéis de AWS Identity and Access Management (IAM) e grupos de log do CloudWatch.

Ele se destaca por sua **integração flexível com o Amazon Simple Queue Service (SQS)**, permitindo que você escolha entre:
* Provisionar uma **nova fila SQS** e configurá-la como um gatilho para a Lambda.
* Ou, utilizar uma **fila SQS existente** como gatilho, conectando a Lambda a uma fila preexistente em sua conta AWS.

Projetado para ser consumido como um **módulo Terraform desacoplado** dentro de uma pipeline de CI/CD (como o GitHub Actions), este projeto facilita implantações automatizadas, consistentes e seguras em diversos ambientes.

---

## ✨ Funcionalidades Principais

* **Implantação de AWS Lambda:** Provisiona uma função AWS Lambda altamente configurável, pronta para executar seu código de backend.
* **Integração Condicional e Flexível com SQS:**
    * **Criar Nova Fila SQS:** Provisiona automaticamente uma nova fila SQS dedicada e a configura como uma origem de evento para a função Lambda. Inclui as permissões IAM necessárias para a Lambda enviar mensagens para esta nova fila.
    * **Usar Fila SQS Existente:** Conecta a função Lambda a uma fila SQS já existente (identificada pelo seu ARN), configurando-a como uma origem de evento. Também configura as permissões IAM apropriadas para a Lambda consumir mensagens desta fila.
* **Gerenciamento Abrangente de Papéis IAM:** Cria e configura os papéis e políticas IAM essenciais para:
    * Execução da Lambda (`lambda:InvokeFunction`).
    * Registro de logs no CloudWatch (`logs:CreateLogGroup`, `logs:CreateLogStream`, `logs:PutLogEvents`).
    * Interações com SQS: permissões para enviar mensagens para filas criadas por este módulo, e permissões para consumir (receber e deletar mensagens) de filas SQS existentes.
* **Monitoramento com CloudWatch Logs:** Configura um Grupo de Logs dedicado no CloudWatch para a função Lambda, facilitando a coleta e análise de logs.
* **Configuração Específica por Ambiente:** Suporta a injeção de variáveis de ambiente dinâmicas na Lambda, permitindo configurações específicas para cada ambiente de implantação (ex: `dev`, `staging`, `prod`).
* **Robustez com Validações:** Inclui validações intrínsecas do Terraform (`preconditions`) para garantir a consistência das configurações, como a exclusividade mútua das opções de SQS (criar nova VS usar existente).
* **Pronto para CI/CD:** Estruturado para ser facilmente consumido e automatizado via fluxos de trabalho do GitHub Actions ou outras ferramentas de CI/CD.

---

## 🗺️ Estrutura do Projeto e Análise Detalhada dos Arquivos

O projeto segue uma estrutura de módulo Terraform padrão, com um módulo raiz que orquestra submódulos para cada tipo de recurso (CloudWatch, IAM, Lambda, SQS).

```
skeleton-terraform-template/
├── terraform/
│   ├── main.tf                 # Orquestração principal do módulo raiz e validações de alto nível.
│   ├── locals.tf               # Definição de variáveis locais e padronização de nomes.
│   ├── outputs.tf              # Saídas importantes do módulo raiz para consumo externo.
│   ├── variables.tf            # Definição de todas as variáveis de entrada do módulo raiz.
│   └── modules/
│       ├── cloudwatch/         # Módulo para o Grupo de Logs do CloudWatch.
│       │   ├── main.tf
│       │   ├── outputs.tf
│       │   └── variables.tf
│       ├── iam/                # Módulo para papéis e políticas IAM (com gestão de políticas SQS).
│       │   ├── main.tf
│       │   ├── outputs.tf
│       │   └── variables.tf
│       ├── lambda/             # Módulo para a função AWS Lambda (com validações internas).
│       │   ├── main.tf
│       │   ├── outputs.tf
│       │   └── variables.tf
│       └── sqs/                # Módulo para a Fila SQS (criação condicional).
│           ├── main.tf
│           ├── outputs.tf
│           └── variables.tf
└── README.md                   # Este arquivo de documentação.
```

---

### Arquivos do Módulo Raiz (`terraform/`)

Estes arquivos compõem o módulo principal que integra os submódulos para construir a infraestrutura completa da Lambda.

* `main.tf`
    * **Função:** É o coração do módulo raiz. Ele define o provedor AWS, busca dados de recursos AWS existentes (como o bucket S3 que armazena o código da Lambda), e orquestra a criação de novos recursos chamando os submódulos (`module "lambda"`, `module "iam"`, `module "sqs"`, `module "cloudwatch"`).
    * **Destaques:**
        * Define o `required_providers` (AWS) e `required_version` do Terraform.
        * Utiliza um `data "aws_s3_bucket"` para referenciar o bucket onde o pacote ZIP da Lambda está armazenado.
        * Chama o `module "sqs"` **condicionalmente** (`count = var.create_sqs_queue && !var.use_existing_sqs_trigger ? 1 : 0`), garantindo que uma nova fila SQS seja criada apenas se a variável `create_sqs_queue` for `true` e `use_existing_sqs_trigger` for `false`.
        * Invoca o `module "lambda"`, passando todas as configurações necessárias (nome, ARN da role IAM, S3 bucket/key, handler, runtime, e variáveis de ambiente).
        * Chama o `module "iam"`, que é responsável por criar as roles e políticas, passando informações sobre as configurações de SQS (nova ou existente) para que as permissões corretas sejam geradas.
        * Chama o `module "cloudwatch"` para configurar o grupo de logs associado à Lambda.
        * Define o recurso `aws_lambda_event_source_mapping` **condicionalmente** (`count = var.use_existing_sqs_trigger ? 1 : 0`) para criar a trigger da Lambda para uma fila SQS existente.
        * Inclui blocos `lifecycle.precondition` nos recursos apropriados para validar a **mutualidade exclusiva** entre `create_sqs_queue` e `use_existing_sqs_trigger`, e para garantir que `existing_sqs_queue_arn` seja fornecido quando uma fila existente é usada como trigger.

* `locals.tf`
    * **Função:** Centraliza a definição de variáveis locais para padronizar nomes de recursos e outras configurações derivadas das variáveis de entrada. Isso garante consistência e evita a duplicação de lógica por todo o módulo.
    * **Destaques:**
        * Define `environment_suffix` para adicionar `-dev`, `-preview`, etc., aos nomes de recursos, exceto para o ambiente `prod`.
        * Cria nomes padronizados para a função Lambda (`lambda_name`), suas roles e políticas IAM (`lambda_role_name`, `logging_policy_name`, `publish_policy_name`, `consume_policy_name`), e o grupo de logs do CloudWatch.
        * Define o nome da fila SQS a ser criada (`queue_name`).
        * Mescla variáveis de ambiente globais (`global_env_vars`) com variáveis específicas do ambiente (`environments[var.environment]`) para serem injetadas na Lambda (`merged_env_vars`).
        * Define o handler e runtime padrão para a função Lambda (`lambda_handler`, `lambda_runtime`).

* `outputs.tf`
    * **Função:** Exporta valores importantes dos recursos criados por este módulo. Essas saídas podem ser consumidas por outros módulos Terraform, pipelines de CI/CD ou para fins de auditoria e depuração.
    * **Destaques:**
        * Exporta o ARN (`lambda_arn`) e o nome (`lambda_function_name`) da função Lambda provisionada.
        * Exporta o nome do bucket S3 (`bucket_name`) referenciado para o código da Lambda.
        * Exporta condicionalmente a URL (`sqs_queue_url`) e o ARN (`sqs_queue_arn`) da fila SQS, utilizando a função `try` para retornar "SQS not created by this deploy" se a fila não for provisionada por este módulo.
        * Exporta o ARN da fila SQS existente (`existing_sqs_trigger_arn`), se ela for utilizada como gatilho para a Lambda, ou uma mensagem indicando o contrário.

* `variables.tf`
    * **Função:** Define todas as variáveis de entrada que o módulo raiz aceita. Cada variável possui uma descrição clara, tipo e validações, quando aplicável, garantindo que os dados de entrada estejam no formato esperado.
    * **Destaques:**
        * Define variáveis essenciais para a configuração da AWS (`aws_region`), identificação do projeto (`project_name`), e o ambiente de deploy (`environment`).
        * Define mapas para `global_env_vars` e `environments` para passar variáveis de ambiente para a Lambda.
        * Inclui `s3_bucket_name` para o bucket S3 que armazena o código da Lambda.
        * Introduz as variáveis de controle booleanas `create_sqs_queue` (para criar uma **nova** SQS) e `use_existing_sqs_trigger` (para usar uma **existente** como trigger).
        * Define `existing_sqs_queue_arn` para o ARN da fila SQS existente (obrigatório se `use_existing_sqs_trigger` for `true`).
        * **Validações:** Embora a validação de mutualidade exclusiva não seja feita diretamente aqui (no nível do módulo), as variáveis são preparadas para serem usadas em `lifecycle.precondition` no `main.tf` e no módulo `lambda`.

---

### Módulos Internos (`terraform/modules/`)

Estes são submódulos que encapsulam a lógica para tipos específicos de recursos, promovendo reusabilidade e uma clara separação de responsabilidades.

#### Módulo `cloudwatch/`

* **Propósito:** Gerencia a criação e configuração de grupos de log do CloudWatch para a função Lambda.
* `main.tf`
    * Cria um recurso `aws_cloudwatch_log_group` com um nome padronizado e uma política de retenção de logs. Configura `prevent_destroy = true` para evitar exclusões acidentais do grupo de logs.
* `outputs.tf`
    * Exporta o nome do grupo de logs criado (`log_group_name`).
* `variables.tf`
    * Define a variável de entrada para o nome do grupo de logs.

#### Módulo `iam/`

* **Propósito:** Gerencia a criação de papéis (roles) e políticas IAM com as permissões mínimas necessárias para a função Lambda e suas interações com outros serviços AWS, especialmente SQS.
* `main.tf`
    * Cria o `aws_iam_role` principal (`lambda_execution_role`) com a política de confiança para o serviço Lambda (`lambda.amazonaws.com`).
    * Anexa uma `aws_iam_role_policy` (`lambda_logging_policy`) para permitir que a Lambda escreva logs no CloudWatch.
    * Cria condicionalmente (`count`) uma `aws_iam_role_policy` para permissões de **publicação** em SQS (`lambda_sqs_publish`), se uma nova fila SQS estiver sendo criada (`var.create_sqs_queue` for `true`). Esta política concede permissões para enviar mensagens para a fila SQS recém-criada.
    * Cria condicionalmente (`count`) uma `aws_iam_role_policy` para permissões de **consumo** de SQS (`lambda_sqs_consume`), se uma fila SQS existente estiver sendo usada como trigger (`var.use_existing_sqs_trigger` for `true`). Esta política concede permissões para receber e deletar mensagens da fila SQS existente.
* `outputs.tf`
    * Exporta o ARN do papel IAM criado para a Lambda (`role_arn`).
* `variables.tf`
    * Define variáveis de entrada para os nomes dos papéis e políticas.
    * Recebe o ARN da fila SQS (seja a nova ou a existente) para configurar as permissões de publicação/consumo.
    * Inclui as variáveis booleanas `create_sqs_queue` e `use_existing_sqs_trigger` para controlar a criação condicional das políticas SQS.
    * Define `consume_policy_name` para a política de consumo.

#### Módulo `lambda/`

* **Propósito:** Define a função AWS Lambda em si, incluindo suas propriedades básicas e validações de configuração.
* `main.tf`
    * Cria o recurso `aws_lambda_function`, configurando seu nome, o ARN do papel de execução, o handler, o runtime, o bucket S3 e a chave do objeto ZIP do código, e as variáveis de ambiente.
    * Contém blocos `lifecycle.precondition` para garantir que:
        * `create_sqs_queue` e `use_existing_sqs_trigger` não sejam `true` ao mesmo tempo (validação de mutualidade exclusiva).
        * O `existing_sqs_queue_arn` seja fornecido e não vazio se `use_existing_sqs_trigger` for `true`.
* `outputs.tf`
    * Exporta o nome (`lambda_function_name`) e o ARN (`lambda_arn`) da função Lambda criada.
* `variables.tf`
    * Define variáveis de entrada para as propriedades da função Lambda (nome, ARN da role, S3 bucket/key, variáveis de ambiente, handler, runtime).
    * Recebe as variáveis de controle de SQS (`create_sqs_queue`, `use_existing_sqs_trigger`, `existing_sqs_queue_arn`) necessárias para as validações de `precondition` e para a construção de nomes/permissões relevantes.

#### Módulo `sqs/`

* **Propósito:** Encapsula a lógica para criar uma nova fila SQS. Este módulo é chamado apenas quando a variável `create_sqs_queue` no módulo raiz é `true` (e `use_existing_sqs_trigger` é `false`).
* `main.tf`
    * Cria o recurso `aws_sqs_queue` com o nome especificado.
* `outputs.tf`
    * Exporta a URL (`queue_url`) e o ARN (`queue_arn`) da fila SQS criada.
* `variables.tf`
    * Define a variável de entrada para o nome da fila SQS.

---

## 🚀 Primeiros Passos

Este projeto Terraform é projetado para ser implantado de forma automatizada, idealmente por meio de uma **pipeline de CI/CD** (como o GitHub Actions). A pipeline será responsável por configurar as credenciais da AWS, inicializar o Terraform, e executar os comandos `terraform plan` e `terraform apply`.

### Pré-requisitos

Para utilizar este módulo Terraform, você precisará:

* **Conta AWS:** Uma conta AWS ativa com as permissões necessárias para provisionar os recursos (Lambda, IAM, SQS, CloudWatch).
* **Bucket S3 AWS:** Um bucket S3 para armazenar o pacote ZIP do código da sua Lambda. Este bucket é referenciado pela variável `s3_bucket_name`.
* **Terraform CLI:** O executável do Terraform CLI deve estar disponível no ambiente de execução (versão mínima `>= 1.0.0`).
* **Código da Lambda:** Seu código-fonte da função Lambda, empacotado em um arquivo ZIP e carregado no S3 bucket especificado.
* **Ferramenta de CI/CD:** Um fluxo de trabalho de CI/CD (ex: GitHub Actions) configurado para interagir com sua conta AWS e executar os comandos Terraform.

### Variáveis de Entrada

As seguintes variáveis podem ser configuradas ao chamar este módulo Terraform. Elas são tipicamente passadas por meio de um arquivo `.tfvars` ou diretamente via linha de comando/variáveis de ambiente em sua pipeline de CI/CD.

| Nome da Variável | Tipo | Descrição | Padrão | Obrigatório |
| :------------------------- | :------------ | :-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | :----------------------- | :---------- |
| `aws_region` | `string` | Região AWS onde todos os recursos serão provisionados. | `"us-east-1"` | Não |
| `project_name` | `string` | Nome base do projeto, usado para nomear recursos como a Lambda, roles IAM e filas SQS. Geralmente derivado do nome do repositório. | N/A | Sim |
| `environment` | `string` | Nome do ambiente de implantação (ex: `dev`, `prod`, `preview`). Afeta o sufixo dos nomes dos recursos. | N/A | Sim |
| `global_env_vars` | `map(string)` | Um mapa de variáveis de ambiente globais a serem injetadas na função Lambda, aplicáveis a todos os ambientes. | `null` (deve ser `{}`) | Sim |
| `environments` | `map(object)` | Um mapa de objetos onde cada chave representa um ambiente (ex: `dev`, `prod`) e o valor é um objeto contendo variáveis de ambiente específicas para aquele ambiente da Lambda. | `null` (deve ser `{}`) | Sim |
| `s3_bucket_name` | `string` | Nome do bucket S3 onde o artefato de implantação da Lambda (arquivo ZIP) está armazenado. | N/A | Sim |
| `create_sqs_queue` | `bool` | Defina como `true` para que este módulo provisione uma **nova** fila SQS e a associe como gatilho da Lambda. Definir como `false` impede a criação da fila. | `false` | Não |
| `use_existing_sqs_trigger` | `bool` | Defina como `true` para que a função Lambda seja configurada com uma fila SQS **existente** como gatilho. Se `true`, `existing_sqs_queue_arn` se torna obrigatório. | `false` | Não |
| `existing_sqs_queue_arn` | `string` | O **ARN (Amazon Resource Name)** da fila SQS existente a ser usada como gatilho para a Lambda. **Obrigatório se `use_existing_sqs_trigger` for `true`.** | `""` | Não |

**Observação Importante sobre a Configuração do SQS:**
Você **deve escolher uma única estratégia** para a integração do SQS. Definir `create_sqs_queue` e `use_existing_sqs_trigger` como `true` simultaneamente resultará em um erro de validação do Terraform (`precondition`). Além disso, se `use_existing_sqs_trigger` for `true`, o `existing_sqs_queue_arn` deve ser fornecido e não pode ser vazio.

### Saídas do Módulo

O módulo fornece as seguintes saídas, que podem ser úteis para processos subsequentes em sua pipeline (ex: configurar um API Gateway para invocar a Lambda) ou para fins de auditoria e depuração.

| Nome da Saída | Descrição |
| :--------------------------- | :------------------------------------------------------------------------- |
| `lambda_arn` | O ARN (Amazon Resource Name) completo da função Lambda provisionada. |
| `lambda_function_name` | O nome final da função Lambda provisionada. |
| `bucket_name` | O nome do bucket S3 onde o código da Lambda está armazenado. |
| `sqs_queue_url` | A URL da fila SQS, **se criada por esta implantação**. Caso contrário, "SQS not created by this deploy". |
| `sqs_queue_arn` | O ARN da fila SQS, **se criada por esta implantação**. Caso contrário, "SQS not created by this deploy". |
| `existing_sqs_trigger_arn` | O ARN da fila SQS **existente** usada como gatilho para a Lambda, **se aplicável**. Caso contrário, "No existing SQS queue used as trigger". |

---

## 💻 Uso em Pipelines de CI/CD (Ex: GitHub Actions)

Este módulo é construído para ser consumido por uma pipeline de CI/CD. Seu fluxo de trabalho geralmente seguirá estas etapas de alto nível:

1. **Checkout do Código:** Obter o código do seu repositório que contém a chamada a este módulo Terraform.

2. **Configurar Credenciais AWS:** Utilizar uma Action oficial (ex: `aws-actions/configure-aws-credentials`) para autenticar o runner na sua conta AWS.

3. **Configurar Terraform:** Utilizar uma Action (ex: `hashicorp/setup-terraform`) para instalar a versão correta do Terraform CLI.

4. **Geração de `tfvars`:** Gerar um arquivo `terraform.auto.tfvars.json` com todas as variáveis de entrada necessárias para este módulo, incluindo aquelas derivadas dinamicamente (como `project_name` e `environment`).

5. **Terraform Init:** Inicializar o diretório de trabalho do Terraform, configurando o backend para o estado remoto (ex: um bucket S3).

6. **Terraform Plan:** Gerar um plano de execução, que detalha as mudanças que o Terraform fará na sua infraestrutura, sem aplicá-las.

7. **Terraform Apply:** Aplicar as mudanças definidas no plano para provisionar ou atualizar os recursos na AWS.

Aqui está um **exemplo conceitual** de como você chamaria este módulo em um `main.tf` do seu repositório de aplicação, e um trecho de um fluxo de trabalho do GitHub Actions que o utilizaria:

```terraform
# Exemplo de uso deste módulo em um main.tf do seu repositório de aplicação:
module "my_consumer_lambda" {
  source = "git::https://github.com/iamelisandromello/skeleton-terraform-template.git?ref=main" # Use a tag ou branch desejada

  aws_region               = var.aws_region
  project_name             = var.project_name
  environment              = var.environment
  global_env_vars          = var.global_env_vars
  environments             = var.environments
  s3_bucket_name           = var.s3_bucket_name
  create_sqs_queue         = var.create_sqs_queue
  use_existing_sqs_trigger = var.use_existing_sqs_trigger
  existing_sqs_queue_arn   = var.existing_sqs_queue_arn
}

output "consumer_lambda_url" {
  value = module.my_consumer_lambda.lambda_arn
}
```

```yaml
name: Deploy My Consumer Lambda

on:
  push:
    branches:
      - main
      - develop
  workflow_dispatch:

env:
  AWS_REGION: us-east-1
  AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
  AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
  PROJECT_NAME: my-api-gateway      # Nome deste projeto (API Gateway)
  ENVIRONMENT: staging             # Ambiente (vindo de input/branch)
  S3_BUCKET_NAME: my-shared-terraform-state # Bucket para o state do Terraform deste projeto

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout API Gateway Code
        uses: actions/checkout@v4

      - name: Setup Terraform
        uses: iamelisandromello/skeleton-pipeline-template/setup-terraform@main # Reutilize sua Action!
        with:
          terraform_version: '1.5.6'
          environment: ${{ env.ENVIRONMENT }}
          project_name: ${{ env.PROJECT_NAME }}
          s3_bucket_name: ${{ env.S3_BUCKET_NAME }}
          aws_access_key_id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws_secret_access_key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}

      # NOTA: Você precisaria de uma action generate-tfvars para o API Gateway
      # que passasse as variáveis necessárias, incluindo o nome da Lambda target.
      # Exemplo de como a Lambda Target Name seria passada:
      # - name: Generate API TFVars
      #   uses: iamelisandromello/skeleton-pipeline-template/generate-api-tfvars@main # Nova Action customizada?
      #   with:
      #     target_lambda_name: my-lambda-${{ env.ENVIRONMENT }} # Nome da sua Lambda!

      - name: Terraform Plan and Apply
        uses: iamelisandromello/skeleton-pipeline-template/plan-apply-terraform@main # Reutilize sua Action!
        with:
          PROJECT_NAME: ${{ env.PROJECT_NAME }}
          S3_BUCKET_NAME: ${{ env.S3_BUCKET_NAME }}
          ENVIRONMENT: ${{ env.ENVIRONMENT }}
          AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
          AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          # Não precisaria de GLOBAL_ENV_VARS_JSON/ENVIRONMENTS_JSON aqui, pois são específicos da Lambda.
          terraform_path: . # O Terraform root está na raiz deste repositório
```

---

## ✅ Boas Práticas e Recomendações

* **Versionamento do Módulo:** Considere versionar este módulo (usando tags Git como `v1.0.0`) e referenciá-lo em seus projetos de consumo (ex: `source = "git::https://github.com/iamelisandromello/skeleton-terraform-template.git?ref=v1.0.0"`). Isso garante estabilidade em seus deploys.
* **Reuso e Modularidade:** Este projeto exemplifica o reuso de módulos. Encoraje a criação de outros módulos para encapsular mais recursos da AWS.
* **Gerenciamento de Segredos:** Sempre utilize AWS Secrets Manager ou variáveis de ambiente seguras (como GitHub Secrets) para credenciais e dados sensíveis, nunca diretamente no código ou arquivos de configuração versionados.
* **Validações:** Aproveite ao máximo os blocos `validation` e `lifecycle.precondition` do Terraform para garantir a integridade e consistência de sua infraestrutura antes do apply.
* **State Remoto:** Sempre utilize um backend remoto (como S3 com DynamoDB para bloqueio de estado) para armazenar o estado do Terraform, essencial para colaboração e resiliência.
* **Revisão de Planos:** Em ambientes de produção, é uma boa prática configurar a pipeline para exigir aprovação manual após a etapa de `terraform plan` e antes do `terraform apply`.
