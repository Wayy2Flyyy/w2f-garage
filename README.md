<div align="center">

# 🚗 w2f-garage

**Production-oriented FiveM property garage framework for QBCore, Qbox, and ESX.**

<br>

![QBCore](https://img.shields.io/badge/QBCore-supported-2ea44f?style=for-the-badge)
![Qbox](https://img.shields.io/badge/Qbox-supported-2ea44f?style=for-the-badge)
![ESX](https://img.shields.io/badge/ESX-supported-2ea44f?style=for-the-badge)

![Status](https://img.shields.io/badge/release-preview-orange?style=flat-square)
![Lua](https://img.shields.io/badge/Lua-5.4-000080?style=flat-square&logo=lua&logoColor=white)
![oxmysql](https://img.shields.io/badge/oxmysql-required-blue?style=flat-square)
![ox__lib](https://img.shields.io/badge/ox__lib-required-blue?style=flat-square)

</div>

> [!NOTE]
> **Preview release:** stable enough for testing and implementation, with ongoing improvements and documentation updates.

<br>

## 🖼️ Preview

<div align="center">

<img width="1486" height="842" alt="w2f-garage preview 1" src="https://github.com/user-attachments/assets/7accf62f-a3ac-4fb7-9bdb-f74f0af7da9d" />

<img width="1484" height="843" alt="w2f-garage preview 2" src="https://github.com/user-attachments/assets/f18a2123-63d5-4138-9844-4c2601014a98" />

<img width="1489" height="836" alt="w2f-garage preview 3" src="https://github.com/user-attachments/assets/47ac0604-a472-4cc8-8dc2-1d8eb3466937" />

</div>

<br>

## ✨ Features

| | |
|---|---|
| 🔌 **Framework bridge** | No direct `QBCore` / `ESX` calls in garage logic |
| 🏠 **Property garages** | Dynasty 8 low / medium / high-end + future Eclipse 50-car |
| 🛡️ **Server-authoritative** | Purchase, store, spawn, slots, and state |
| 🚙 **Interior abstraction** | Physical display vehicles when coords are configured |
| 🎚️ **Slot manager** | Assign, swap, move floor, move garage, anti-duplicate plates |
| 🧩 **Configurable bridges** | ox_lib, ox_target, oxmysql + fuel / keys / notify / inventory |
| 🌑 **Premium dark NUI** | Public garages + property dashboard |
| 🛠️ **Admin tools** | Recovery commands |
| 🗄️ **Additive SQL only** | Manual install |

<br>

## 📦 Dependencies

| Resource | Status | Link |
|----------|--------|------|
| **ox_lib** | Required | [overextended/ox_lib](https://github.com/overextended/ox_lib) |
| **oxmysql** | Required | [overextended/oxmysql](https://github.com/overextended/oxmysql) |
| **ox_target** | Recommended | [overextended/ox_target](https://github.com/overextended/ox_target) |

<br>

## 🚀 Quick start

1. **Import the schema** — run `sql/install.sql` manually (after backup).
2. **Configure** `shared/config.lua` — framework, database table mapping, property options.
3. **Add to your server.cfg** — `ensure w2f-garage` after ox_lib, oxmysql, and your framework.
4. **Build the UI:**
   ```bash
   cd web && npm install && npm run build
   ```

<br>

<div align="center">

---

*Stay2Flyyy*

</div>
