# TW-AWS-FinOps-Tagging-Tool

A turnkey PowerShell solution for **AWS-only** environments that streamlines:

* **Exporting** resource metadata and existing tags into CSVs
* **Editing** tag values in a familiar spreadsheet format
* **Applying** updated tags back to AWS resources across multiple accounts and regions via SSO

> Created by **Florent Lanternier** at **TeamWork**.

---

## 🚀 1. Quick Start (for all users)

1. **Open PowerShell as Administrator**
   *(Right-click on PowerShell and choose "Run as administrator")*

2. **Clone the repository**:

   ```powershell
   git clone https://github.com/Fllan/TW-AWS-FinOps-Tagging-Tool.git
   cd TW-AWS-FinOps-Tagging-Tool
   ```

3. **Install required AWS modules** (admin rights required):

   ```powershell
   Install-Module -Name AWS.Tools.Common, AWS.Tools.EC2, AWS.Tools.S3, AWS.Tools.ElasticFileSystem, AWS.Tools.RDS, AWS.Tools.SavingsPlans, AWS.Tools.Pricing -Force
   ```

4. **Ensure SSO access**: You must be able to authenticate with AWS using `aws sso login` or equivalent

5. **Run the tool**:

   ```powershell
   pwsh .\FinOpsTaggingTool.ps1
   ```

> 📌 This tool is built **exclusively for AWS** environments.



---



## 🔧 2. Prerequisites

* **Windows 10+ / PowerShell 7+**
* **Admin rights** to install required modules
* **AWS SSO** configured for your user and account access
* **Git** or ZIP download to retrieve the repo

---

## 🗂️ 3. Repository Layout

```
config/                # Organization-specific configuration files (SSO, account list, tag keys)
csv/                   # Edited CSVs go here before applying
docs/                  # Contains detailed README files per component
logs/                  # Log output from tool runs
scripts/
  ├─ functions/        # Reusable helpers (SSO login, logging, etc.)
  └─ core/             # Tagging logic per AWS service (export/apply)
FinOpsTaggingTool.ps1  # Main entry script
README.md              # This file (project overview)
```



---



## ⚙️ 4. Configuration

1. **Copy template**:

   ```
   config/ClientTemplate.psd1 → config/MyOrg.psd1
   ```

2. **Edit** your new file:

   * Set your SSO portal URL, role name, region
   * List your AWS account IDs and regions
   * Define required tag keys (e.g., `Environment`, `Owner`, `CostCenter`)

3. Save and use it—no further setup needed

📘 More info in [config/README.md](config/README.md)



---



## 🛠️ 5. Usage

### A. Export Tags

```powershell
pwsh .\FinOpsTaggingTool.ps1
```

* Select your `MyOrg.psd1` config file
* Choose account(s), service(s), and action: **Export**
* Output CSVs will appear in `csv/output/`

### B. Edit Tags

* Open CSV files using Excel or another editor
* Fill in missing tag values, leave blank to skip
* Follow the format detailed here : [csv/README.md](csv/README.md)
* Save into `csv/input/`

📘 More info in [csv/README.md](csv/README.md)

### C. Apply Tags

* Re-run the tool:

  ```powershell
  pwsh .\FinOpsTaggingTool.ps1
  ```
* Select your config, pick **Apply**, confirm account and service
* Tags will be applied based on edited CSVs



---



## 🧠 6. Internals

* All AWS service-specific logic lives in [scripts/core/README.md](scripts/core/README.md)
* General helper utilities (menus, SSO auth, logs) live in [scripts/functions/README.md](scripts/functions/README.md)
* Input/Output CSV rules are documented in [csv/README.md](csv/README.md)
* Configuration details
*  covered in [config/README.md](config/README.md)



---



## 📩 7. Support & Next Steps

* **Logs**: Check `logs/` folder for detailed operation output
* **Extend**: Add support for more AWS services using `Export-*` and `Set-ResourceTagsFromCsv.ps1`



---



> Created by **Florent Lanternier**
> TeamWork FinOps Team
