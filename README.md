# rUNC — улучшенный Unified Naming Convention для русскоязычных

**rUNC** — это переработанная и усовершенствованная версия **Unified Naming Convention (UNC)**, адаптированная специально для русскоязычного сообщества Roblox‑разработчиков и тестировщиков.  
UNC — это стандарт, созданный для унификации API и названий функций в окружении эксплойтов, чтобы скрипты, написанные под один исполнители, могли без доработок работать и на других, если они поддерживают этот стандарт.

---

## 🔹 Преимущества rUNC

- **Полная локализация** — все сообщения, проверки и документация на русском языке!!!
- **Расширенные проверки** — тестируются больше API‑функций и сценариев, включая редкие и граничные случаи. (Хоть некоторые и отсутствуют по типу WebSocket, но постепенно будут добавляться)
- **Повышенная надёжность** — защита от крашей, рекурсий и ложных срабатываний при проверке метаметодов и хуков.
- **Чистая архитектура** — код структурирован и легко расширяется под новые функции или стандарты. (Ну прям очень легко структуирован - aka монолитный код!!!)
- **Совместимость** — сохраняет обратную совместимость с оригинальным UNC, но добавляет больше возможностей для диагностики и любых debug проверок.
- **Фокус на безопасность** — все проверки выполняются в локальной среде, ничего не логируется, до определённого момента :D

---

## 📌 Зачем нужен rUNC

- Чтобы скрипты работали одинаково на разных экзекьюторах, поддерживающих UNC, подытоживая тему о том что разные Executors могут подделывать функции.
- Чтобы быстро понять, какие функции доступны и как они реализованы в конкретном окружении.
- Пофиксить функции в своём Executor???

---

## 🚀 Запуск

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/TesterTD/rUNC/main/rUNC.lua"))()
```

| Клиент       | Тип       | Итого                                                                 | Skid Rate                                                                 | Обновление                                                                 | Статус                                                                 |
|--------------|-----------|-----------------------------------------------------------------------|----------------------------------------------------------------------------|-----------------------------------------------------------------------------|------------------------------------------------------------------------|
| **bunni.lol** | 🖥 ПК      | ![Итого](https://img.shields.io/badge/268%2F317-84%25-00ff99?style=for-the-badge&logo=starship&logoColor=white)    | ![Skid](https://img.shields.io/badge/35%2F317-11%25-00ff99?style=for-the-badge&logo=checkmarx&logoColor=white)           | ![Updated](https://img.shields.io/badge/Обновлено-08.09.2025-1e90ff?style=for-the-badge&logo=github)          | ![Status](https://img.shields.io/badge/Отличный%20executor-00ff99?style=for-the-badge&logo=rocket&logoColor=white)         |
| **Delta**     | 📱 Мобильный | ![Итого](https://img.shields.io/badge/239%2F286-83%25-32cd32?style=for-the-badge&logo=android&logoColor=white)          | ![Skid](https://img.shields.io/badge/39%2F286-13%25-32cd32?style=for-the-badge&logo=checkmarx&logoColor=white)                 | ![Updated](https://img.shields.io/badge/Обновлено-08.09.2025-1e90ff?style=for-the-badge&logo=github)          | ![Good](https://img.shields.io/badge/Норм%20Executor-32cd32?style=for-the-badge&logo=thumbsup&logoColor=white)   |
| **Xeno**      | 🖥 ПК      | ![Итого](https://img.shields.io/badge/159%2F234-67%25-ffd700?style=for-the-badge&logo=lua&logoColor=black)         | ![Skid](https://img.shields.io/badge/50%2F234-21%25-ffa500?style=for-the-badge&logo=alert&logoColor=white)                | ![Updated](https://img.shields.io/badge/Обновлено-08.09.2025-1e90ff?style=for-the-badge&logo=github)          | ![Status](https://img.shields.io/badge/Подделывают%20некоторые%20функции%2C%20но%20неплохо%20для%20Level%203-ffd700?style=for-the-badge&logo=balance-scale&logoColor=black)    |
| **Velocity**  | 🖥 ПК      | ![Crashed](https://img.shields.io/badge/Провалился%20на%20половине%20теста-ff0000?style=for-the-badge&logo=skull&logoColor=white)                  | ![Skid](https://img.shields.io/badge/Отвратительные%20метаметод%20хуки%20%F0%9F%98%A1-ff0000?style=for-the-badge&logo=skull-crossbones&logoColor=white) | ![Updated](https://img.shields.io/badge/Обновлено-08.09.2025-1e90ff?style=for-the-badge&logo=github)          | ![Unstable](https://img.shields.io/badge/%F0%9F%92%80%20Параша%20Полная-critical?style=for-the-badge&logo=skull&logoColor=white)        |

