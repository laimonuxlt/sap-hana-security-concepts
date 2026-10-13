# Security Concepts – SAP HANA Cloud HDI Container

An HDI (HANA Deployment Infrastructure) database module that demonstrates **role-based access control** and **row-level security** on a small sales data model in SAP HANA Cloud.

It contains two tables, one calculation view, an analytic privilege that filters rows by sales region, and three roles for different kinds of users.

## Contents

- [Project structure](#project-structure)
- [Data model](#data-model)
- [Security model](#security-model)
- [Prerequisites](#prerequisites)
- [Configuration](#configuration)
- [Deployment](#deployment)
- [Verifying the setup](#verifying-the-setup)
- [Security notes](#security-notes)

## Project structure

```
.
├── package.json                      # deploy script + dependencies
├── .env                              # local HDI service credentials (git-ignored)
├── .gitignore
└── src/
    ├── .hdiconfig                    # maps file suffixes to HDI build plugins
    ├── tables/
    │   ├── PRODUCTS.hdbtable
    │   └── SALES.hdbtable
    ├── calculation_views/
    │   └── CV_SALES_ANALYSIS.hdbcalculationview
    ├── privileges/
    │   └── sales_region_privilege.hdbanalyticprivilege
    └── roles/
        ├── analyst_role.hdbrole
        ├── app_service_role.hdbrole
        └── developer_role.hdbrole
```

## Data model

### Tables

**`PRODUCTS`**

| Column         | Type           | Notes       |
| -------------- | -------------- | ----------- |
| `PRODUCT_ID`   | INTEGER        | Primary key |
| `PRODUCT_NAME` | NVARCHAR(100)  |             |
| `CATEGORY`     | NVARCHAR(50)   |             |
| `PRICE`        | DECIMAL(10,2)  |             |
| `STOCK`        | INTEGER        |             |

**`SALES`**

| Column       | Type           | Notes                         |
| ------------ | -------------- | ----------------------------- |
| `SALE_ID`    | INTEGER        | Primary key                   |
| `PRODUCT_ID` | INTEGER        | Refers to `PRODUCTS.PRODUCT_ID` |
| `REGION`     | NVARCHAR(20)   | Used for row-level filtering  |
| `COUNTRY`    | NVARCHAR(50)   |                               |
| `SALE_DATE`  | DATE           |                               |
| `QUANTITY`   | INTEGER        |                               |
| `AMOUNT`     | DECIMAL(15,2)  |                               |

### Calculation view: `CV_SALES_ANALYSIS`

A `CUBE` calculation view (aggregation output) that left-outer-joins `SALES` to `PRODUCTS` on `PRODUCT_ID`.

- **Measures:** `QUANTITY`, `AMOUNT` (both `SUM`)
- **Attributes:** `SALE_ID`, `PRODUCT_ID`, `REGION`, `COUNTRY`, `SALE_DATE`, `PRODUCT_NAME`, `CATEGORY`, `PRICE`, `STOCK`
- **Privilege check:** `applyPrivilegeType="SQL_ANALYTIC_PRIVILEGE"`, so queries against the view are filtered by any analytic privileges granted to the user.

## Security model

### Analytic privilege: `sales_region_privilege`

Restricts `CV_SALES_ANALYSIS` to rows where `REGION` matches the pattern `EMEA*` (operator `CP`, "contains pattern"). A user holding this privilege sees only EMEA sales rows when querying the view.

### Roles

| Role                | Purpose                         | Grants                                                                                                  |
| ------------------- | ------------------------------- | ------------------------------------------------------------------------------------------------------- |
| `analyst_role`      | Reporting users                 | `SELECT` on the container schema, plus the `sales_region_privilege` analytic privilege                  |
| `app_service_role`  | Application / technical service | `SELECT` on view `CV_SALES_ANALYSIS`, plus `SELECT` on the container schema                             |
| `developer_role`    | Developers                      | `SELECT`, `INSERT`, `UPDATE`, `DELETE`, `EXECUTE` on the container schema                               |

> Roles are created inside the HDI container. To give them to a database user, tehy need be granted through platform's HDI administration tooling.
