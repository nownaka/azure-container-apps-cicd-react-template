# azure-container-apps-cicd-react-template

インフラに Azure コンテナサービス群を利用した、 React アプリの CI/CD 環境が簡単に構築できるテンプレートリポジトリです。

## 環境

- macOS: `15.0.1`
- Visual Studio Code: `1.95.1`
  - Bicep(拡張機能): `v0.30.23`

## 前提

### ローカル PC

- git がインストールされていること。

### Azure

- Azure アカウントを所有していること。
- 作業アカウントに、サブスクリプションスコープの所有者ロールが割り当てられていること

## テンプレートについて

### ディレクトリ構造

```
.
├── .github
│   └── workflows
│       └── build_and_deploy.yaml
├── app
├── infra
│   ├── modules
│   │   ├── containerapps.bicep
│   │   ├── environment.bicep
│   │   ├── registries.bicep
│   │   ├── roleAssignments.json
│   │   ├── roleAssignmentsFromARM.bicep
│   │   ├── userAssignedIdentities.bicep
│   │   └── workspaces.bicep
│   ├── main.bicep
│   ├── main.bicepparam
├── .gitignore
├── docker-compose.yml
├── Dockerfile
└── README.md
```

### app : React アプリケーション

`npx create-react-app —typescript` で作成されるデフォルトの構成です。

### infra : Azure リソース

作成するリソースの Bicep テンプレートをまとめています。

- リソース一覧と役割：

| No  | リソース名                       | 説明                                                 |
| --- | -------------------------------- | ---------------------------------------------------- |
| 1   | Log Analytics Workspace          | **Azure Container Apps のログ格納・監視する**        |
| 2   | Azure Container Registry         | コンテナイメージを格納する                           |
| 3   | Azure Container Apps Environment | Azure Container Apps の管理、論理的ネットワーク空間  |
| 4   | User Assigned Managed Identity   | イメージのプル、プッシュ、コンテナへのデプロイを行う |
| 5   | Azure Container Apps             | コンテナアプリの実行環境                             |
| 6   | Role Assignments                 | マネージド ID に必要な権限を付与                     |
| 7   | Federated Identity Credentials   | マネージド ID にフェデレーション資格情報を追加       |

- 依存関係：

![image](https://github.com/user-attachments/assets/5e7ce623-77fb-4ccc-b96e-4795dde4cc61)


## 利用方法

> [!WARNING]
> Azure のコンテナサービス群を利用します。
> 利用状況によっては、コストが発生しますが、自己責任でお願いします。


### STEP 1 : テンプレートリポジトリをフォークする

1. リポジトリをフォークする
2. フォークしたリポジトリをローカル PC にクローンする。
3. クローンしたリポジトリを開く。

> [!NOTE]
> フォークとクローンについて
> - https://docs.github.com/ja/pull-requests/collaborating-with-pull-requests/working-with-forks/fork-a-repo
> - https://docs.github.com/ja/repositories/creating-and-managing-repositories/cloning-a-repository


### STEP 2 : Bicep を利用してインフラ環境を構築する

#### 2-1 : bicepparam の設定する

`main.bicepparam` を開き、必要なパラメータを設定します。

```jsx
using './main.bicep'

// リソースの名前は以下のようになります。
// {リソースの略語}-{アプリ名}-{サフィックス}
// Check: https://learn.microsoft.com/ja-jp/azure/cloud-adoption-framework/ready/azure-best-practices/resource-naming

param appName = '{your app name}' // require
param environment = '{your environment name}' // require
param suffix = '' // option

param federatedIdentityCredentialsConfig = { // require
  name: 'github_federation_for_azure_container_services'
  audiendes: ['api://AzureADTokenExchange']
  issuer: 'https://token.actions.githubusercontent.com'
  subjedt: 'repo:{github account name}/{github repository name}:Production'
}

// federatedIdentityCredentialsConfig について
// github の場合、次の形式である必要があります。
// - name：
//    フェデレーテッド ID 資格情報名には、文字 (A ～ Z、a ～ z)、数字、ハイフン、ダッシュのみを含める必要があります。数字または文字で始める必要があります。
//    フェデレーション ID 認証情報の名前は 3 ～ 120 文字以内で、文字 (A ～ Z、a ～ z)、数字、ハイフン、ダッシュのみを含み、数字または文字で始まる必要があります。
// - audiendes:
//    ['api://AzureADTokenExchange'] である必要があります。
// - issuer:
//    'https://token.actions.githubusercontent.com' である必要があります。
// - subjedt:
//    repo:{github account name}/{github repository name}:{entity}
//    - entity：
//       環境 => environment:{environment name}
//       ブランチ => ref:refs/heads/{branch name}

```

`suffix` はオプションとしていますが、リソースによっては グローバルでユニークにする必要があるため、お試しであれば日時を入れるなど被らない名前にすることをおすすめします。

#### 2-2 : リソースをデプロイする

1. `command` + `shift` + `p` でコマンドパレットを起動する。
2. [ Bicep: Deploy Bicep File… ] を選択する。

![image](https://github.com/user-attachments/assets/c949cdb4-71ce-478c-9494-f75771142558)

1. [ infra/main.bicep ] を選択する。

![image](https://github.com/user-attachments/assets/dd22d372-4bd4-4ea5-9cbb-5e674d9dbb22)

1. [ デプロイ名(任意の値) ] を入力して、Enter を押す。

![image](https://github.com/user-attachments/assets/19dc83f9-3df0-4add-a2ba-e2d768700d6b)

1. リソースグループ を選択、または新規作成する。

![image](https://github.com/user-attachments/assets/da690ee8-23d4-44ff-aff8-5b0f6e8bfac0)

- 新規作成する場合：

![image](https://github.com/user-attachments/assets/88f8e70e-01c2-4895-a997-2ec30696d5ed)

![image](https://github.com/user-attachments/assets/fb68d3a1-4042-4d94-9bb5-78728d0ea3b4)

1. [ infra/main.bicepparam ] を選択する。

![image](https://github.com/user-attachments/assets/c8add64e-4f6e-46b5-a2d7-7e41273e6fb9)

### 2-3 : リソースを確認する

1. vscode 上のターミナルに URL が表示されるので、アクセスしてデプロイ結果を確認する。

- ターミナル：

![image](https://github.com/user-attachments/assets/92a4d546-e47a-459e-a563-b161203947d0)

- デプロイ結果：

![image](https://github.com/user-attachments/assets/9b0f821f-33f2-4fd9-b371-5cd53dc7a59a)

1. [ リソースグループに移動 ] を新規タブで開き、リソース一覧の中から、 [<コンテナアプリ>] を選択する。

![image](https://github.com/user-attachments/assets/9d9c703a-af4a-44e3-a9b7-d9b09d31f738)

1. コンテナアプリの URL にアクセスし、下記画面が表示されることを確認する。

![image](https://github.com/user-attachments/assets/dfd67818-eda4-4b49-841c-18f256f911fd)

![image](https://github.com/user-attachments/assets/854eb271-a42f-480c-964b-30d53d287eaa)

### STEP 3 : GitHub Action 用に変数とシークレットを登録する

1. デプロイ結果の[ 出力 ] を選択する。（[STEP : 2-3-1 の画面](https://www.notion.so/Azure-GitHub-React-CI-CD-131ab61659bf80b88b8ddeef8e6c754f?pvs=21)）
2. 表示された値を GitHub リポジトリの [Actions secrets and variables] から、 `Production` 環境を作成し、変数とシークレットを登録する。

![image](https://github.com/user-attachments/assets/702d2d5f-230d-4442-9039-fb6b420c2357)

> [!NOTE]
> GitHub Action の変数とシークレットについて
> - https://docs.github.com/ja/actions/security-for-github-actions/security-guides/using-secrets-in-github-actions
> - https://docs.github.com/ja/actions/writing-workflows/choosing-what-your-workflow-does/store-information-in-variables

![image](https://github.com/user-attachments/assets/af08cc60-c387-4b4d-9cfd-5bcb74303667)

| Type     | 名前                          | 説明                                  | 設定値   |
| -------- | ----------------------------- | ------------------------------------- | -------- |
| secret   | AZURE_CLIENT_ID               | マネージド ID のクライアント ID       | 環境依存 |
| secret   | AZURE_TENANT_ID               | テナント ID                           | 環境依存 |
| secret   | AZURE_SUBSCRIPTION_ID         | サブスクリプション ID                 | 環境依存 |
| variable | AZURE_RESOURCE_GROUP          | リソースグループ名                    | 環境依存 |
| variable | AZURE_CONTAINER_REGISTRY_NAME | Azure Container Registry のリソース名 | 環境依存 |
| variable | AZURE_CONTAINER_APP_NAME      | Azure Container Apps のリソース名     | 環境依存 |
| variable | CONTAINER_NAME                | コンテナ名                            | app      |

### STEP 4 : ワークフローを起動させてアプリをデプロイする

適当に変更を加えて `main` ブランチに push します。

または、GitHub Action のワークフローを手動でトリガーしてください。

> [!NOTE]
> ワークフローの手動実行について
> - https://docs.github.com/ja/actions/managing-workflow-runs-and-deployments/managing-workflow-runs/manually-running-a-workflow

### STEP 5 : ワークフローとデプロイを確認する

GitHub Action のワークフローの結果とコンテナアプリにデプロイできていることを確認します。

- GitHub Action：

![image](https://github.com/user-attachments/assets/42cfb684-d32d-480a-ab00-b7dec5144a3f)

- コンテナアプリ：

![image](https://github.com/user-attachments/assets/86dedb23-83b6-432e-b79b-87039177ddb8)
