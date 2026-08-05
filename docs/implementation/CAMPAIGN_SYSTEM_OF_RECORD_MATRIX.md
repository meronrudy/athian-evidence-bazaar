# Campaign System Of Record Matrix

| Field Or State | System Of Record | Campaign Storage |
| --- | --- | --- |
| Contact enrichment profile | Apollo | External IDs, display name, role category, email domain, authority flags, contactability status |
| Outreach sequence state | Apollo | Bounded semantic touch and external reference |
| Commercial account | Salesforce | Salesforce account ID and selected sync state only |
| Contact durability | Salesforce | Salesforce contact ID only |
| Opportunity | Salesforce | Opportunity ID, selected handoff status, value references, sync timestamps |
| Contract | Salesforce | Contracted timestamp and contracted value reference |
| Cash collection | Salesforce or finance system | Cash-collected timestamp and amount reference |
| Developer account | AgEvidence | Optional link to `Agevidence::DeveloperAccount` |
| Developer project | AgEvidence | Optional link in activation or qualification snapshot |
| Source record | AgEvidence | Snapshot counts and linked project/source IDs |
| Signed integration event | AgEvidence | Snapshot counts and accepted event references |
| Evidence gap | AgEvidence | Gap counts and copied reason summary |
| Review decision | AgEvidence | Counts and latest review-state summary |
| Artifact state | AgEvidence | Artifact/order references and local verification metadata |
| Institutional reliance | AgEvidence | Reliance-event references only |
| Campaign attribution | Campaign control plane | Campaign account, touch, path, capability, and handoff records |

## Required State Sets

Campaign account statuses:

`identified`, `researched`, `approved_for_outreach`, `activation_invited`,
`developer_activated`, `evidence_qualified`, `reliance_qualified`,
`commercially_qualified`, `handed_to_salesforce`, `contracted`,
`active_customer`, `paused`, `disqualified`, `archived`.

Activation path types:

`customer_quickstart`, `developer_quickstart`, `python_sdk`,
`cli_project_4030`, `source_record_browser`, `source_record_api`,
`event_inbox`, `artifact_verification`, `webhook_integration`.

Qualification levels:

`unqualified`, `market_qualified`, `developer_activated`,
`evidence_qualified`, `reliance_qualified`, `commercially_qualified`.

## Interpretive Limits

- No campaign field is a scientific approval field.
- No Salesforce stage is a technical qualification field.
- No Apollo reply is a product activation field.
- No quote or sandbox order is a cash-collection field.
