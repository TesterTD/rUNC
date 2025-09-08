# rUNC — улучшенный Unified Naming Convention для русскоязычных

![License](https://img.shields.io/badge/license-MIT-green?style=for-the-badge)
![Language](https://img.shields.io/badge/lang-RU-blue?style=for-the-badge)
![Status](https://img.shields.io/badge/status-active-success?style=for-the-badge)

**rUNC** — это переработанная и усовершенствованная версия **Unified Naming Convention (UNC)**, адаптированная специально для русскоязычного сообщества Roblox‑разработчиков и тестировщиков.  
UNC — это стандарт, созданный для унификации API и названий функций в окружении эксплойтов, чтобы скрипты, написанные под один исполнитель, могли без доработок работать и на других, если они поддерживают этот стандарт.

---

## 🔹 Преимущества rUNC

- **Полная локализация** — все сообщения, проверки и документация на русском языке!!!
- **Расширенные проверки** — тестируются больше API‑функций и сценариев, включая редкие и граничные случаи. (Хоть некоторые и отсутствуют по типу WebSocket, но постепенно будут добавляться)
- **Повышенная надёжность** — защита от крашей, рекурсий и ложных срабатываний при проверке метаметодов и хуков.
- **Чистая архитектура** — код структурирован и легко расширяется под новые функции или стандарты. (Ну прям очень легко структурирован — aka монолитный код!!!)
- **Совместимость** — сохраняет обратную совместимость с оригинальным UNC, но добавляет больше возможностей для диагностики и любых debug‑проверок.
- **Фокус на безопасность** — все проверки выполняются в локальной среде, ничего не логируется, до определённого момента :D

---

## 📌 Зачем нужен rUNC

- Чтобы скрипты работали одинаково на разных экзекьюторах, поддерживающих UNC, подытоживая тему о том, что разные Executors могут подделывать функции.  
- Чтобы быстро понять, какие функции доступны и как они реализованы в конкретном окружении.  
- Пофиксить функции в своём Executor???  

---

![Внимание](https://img.shields.io/badge/⚠️%20ВНИМАНИЕ-critical?style=for-the-badge&logo=github&logoColor=white)  
Недавнее тестирование показало, что такие экзекьюторы, как **KRNL (мобильный инжектор)** и **Arceus X**, могут вызывать краш на старте работы rUNC.  
Предположительно, это связано с проверками `newcclosure`.  
Вопрос, скорее всего, будет решён, как только появится точная информация о причине 
## 🚀 Запуск

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/TesterTD/rUNC/main/rUNC.lua"))()
```

<table style="font-size:28px; text-align:center;">
  <thead>
    <tr>
      <th style="background-color:#ffcccc;">Клиент</th>
      <th style="background-color:#ccffcc;">Тип</th>
      <th style="background-color:#ccccff;">Итого</th>
      <th style="background-color:#fff0b3;">Skid Rate</th>
      <th style="background-color:#e0ccff;">Обновление</th>
      <th style="background-color:#ffd9b3;">Статус</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td><b>bunni.lol</b></td>
      <td>🖥 ПК</td>
      <td><img src="https://img.shields.io/badge/271%2F317-84%25-00ff99"></td>
      <td><img src="https://img.shields.io/badge/33%2F317-10%25-00ff99"></td>
      <td><img src="https://img.shields.io/badge/Обновлено-08.09.2025-1e90ff"></td>
      <td><img src="https://img.shields.io/badge/Отличный%20executor-00ff99"></td>
    </tr>
    <tr>
      <td><b>Delta</b></td>
      <td>📱 Мобильный</td>
      <td><img src="https://img.shields.io/badge/266%2F318-83%25-32cd32"></td>
      <td><img src="https://img.shields.io/badge/40%2F318-12%25-32cd32"></td>
      <td><img src="https://img.shields.io/badge/Обновлено-08.09.2025-1e90ff"></td>
      <td><img src="https://img.shields.io/badge/Норм%20Executor-32cd32"></td>
    </tr>
    <tr>
      <td><b>Xeno</b></td>
      <td>🖥 ПК</td>
      <td><img src="https://img.shields.io/badge/159%2F234-67%25-ffd700"></td>
      <td><img src="https://img.shields.io/badge/50%2F234-21%25-ffa500"></td>
      <td><img src="https://img.shields.io/badge/Обновлено-08.09.2025-1e90ff"></td>
      <td><img src="https://img.shields.io/badge/Подделывают%20некоторые%20функции%2C%20но%20неплохо%20для%20Level%203-ffd700"></td>
    </tr>
    <tr>
      <td><b>Velocity</b></td>
      <td>🖥 ПК</td>
      <td><img src="https://img.shields.io/badge/Провалился%20на%20половине%20теста-ff0000"></td>
      <td><img src="https://img.shields.io/badge/Отвратительные%20метаметод%20хуки%20%F0%9F%98%A1-ff0000"></td>
      <td><img src="https://img.shields.io/badge/Обновлено-08.09.2025-1e90ff"></td>
      <td><img src="https://img.shields.io/badge/%F0%9F%92%80%20Параша%20Полная-critical"></td>
    </tr>
    <tr>
      <td><b>Neverfall</b></td>
      <td>🖥 ПК</td>
      <td><img src="https://img.shields.io/badge/Ожидаются%20результаты-lightgrey"></td>
      <td><img src="https://img.shields.io/badge/Ожидаются%20данные-lightgrey"></td>
      <td><img src="https://img.shields.io/badge/Обновление%20ожидается-lightgrey"></td>
      <td><img src="https://img.shields.io/badge/Нет%20данных-lightgrey"></td>
    </tr>
  </tbody>
</table>

<div style="margin-top:30px; text-align:center;">
  <img src="https://img.shields.io/badge/Important-Если%20вы%20проверили%20какой--то%20Executor%2C%20которого%20нету%20в%20списке%2C%20то%20дайте%20мне%20об%20этом%20знать!-ff69b4" style="transform:scale(1.5);">
</div>

