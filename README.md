<p align="center">
  <img src="logo2.png" alt="rUNC logo" width="320">
</p>

<h1 align="center">🚀 rUNC — улучшенный Unified Naming Convention для русскоязычных</h1>

<p align="center">
  <a href="https://www.gnu.org/licenses/gpl-3.0">
    <img src="https://img.shields.io/badge/license-GPLv3-blue?style=for-the-badge&logo=gnu" alt="License">
  </a>
  <img src="https://img.shields.io/badge/lang-RU-red?style=for-the-badge&logo=google-translate" alt="Language">
  <img src="https://img.shields.io/badge/status-Active-success?style=for-the-badge&logo=github-actions" alt="Status">
  <a href="https://testertd.github.io/rUNC/">
    <img src="https://img.shields.io/badge/📄%20Документация-Открыть-blueviolet?style=for-the-badge&logo=readthedocs" alt="Docs">
  </a>
</p>

---

**rUNC** — это переработанная и усовершенствованная версия **Unified Naming Convention (UNC)**, адаптированная специально для русскоязычного сообщества Roblox‑разработчиков и тестировщиков.  
UNC — это стандарт, созданный для унификации API и названий функций в окружении эксплойтов, чтобы скрипты, написанные под один исполнитель, могли без доработок работать и на других, если они поддерживают этот стандарт.

---

## 🔹 Преимущества rUNC

- 🌐 **Полная локализация** — все сообщения, проверки и документация на русском языке!!!
- 🛠 **Расширенные проверки** — тестируются больше API‑функций и сценариев, включая редкие и граничные случаи. (Хоть некоторые и отсутствуют по типу WebSocket, но постепенно будут добавляться)
- 🛡 **Повышенная надёжность** — защита от крашей, рекурсий и ложных срабатываний при проверке метаметодов и хуков.
- 📂 **Чистая архитектура** — код структурирован и легко расширяется под новые функции или стандарты. (Ну прям очень легко структурирован — aka монолитный код!!!)
- 🔄 **Совместимость** — сохраняет обратную совместимость с оригинальным UNC, но добавляет больше возможностей для диагностики и любых debug‑проверок.
- 🔒 **Фокус на безопасность** — все проверки выполняются в локальной среде, ничего не логируется, до определённого момента :D

---

## 📌 Зачем нужен rUNC

- 📜 Чтобы скрипты работали одинаково на разных экзекьюторах, поддерживающих UNC, подытоживая тему о том, что разные Executors могут подделывать функции.  
- 🔍 Чтобы быстро понять, какие функции доступны и как они реализованы в конкретном окружении.  
- 🛠 Пофиксить функции в своём Executor???  

---

<p align="center">
  <img src="https://img.shields.io/badge/⚠️%20ВНИМАНИЕ-critical?style=for-the-badge&logo=github&logoColor=white" alt="Warning">
</p>

После проведённых тестов установлено, что такие экзекьюторы, как **KRNL (мобильный инжектор)** и **Arceus X**, обладают крайне нестабильными функциями в своей среде.  
При малейшем взаимодействии они вызывают вылет **RobloxPlayer**, что делает их использование ненадёжным.

Исправлять это, на данный момент я не собираюсь, данный Executor не претендует на корректную работу функций.

---

## 🆕 Глобальное обновление

Вышел **глобальный патч** для **debug‑функций** и различных **closures**.  
Обновление улучшает стабильность, расширяет диагностику и повышает совместимость с новыми API.

---

## 🚀 Запуск

📖 **Документация rUNC доступна здесь:**  
👉 [https://testertd.github.io/rUNC/](https://testertd.github.io/rUNC/)

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
      <td><img src="https://img.shields.io/badge/327%2F342-95%25-00ff99"></td>
      <td><img src="https://img.shields.io/badge/13%2F342-3%25-00ff99"></td>
      <td><img src="https://img.shields.io/badge/Обновлено-29.09.2025-1e90ff"></td>
      <td><img src="https://img.shields.io/badge/Отличный%20executor-00ff99"></td>
    </tr>
    <tr>
      <td><b>Delta</b></td>
      <td>📱 Мобильный</td>
      <td><img src="https://img.shields.io/badge/302%2F334-90%25-32cd32"></td>
      <td><img src="https://img.shields.io/badge/23%2F334-6%25-32cd32"></td>
      <td><img src="https://img.shields.io/badge/Обновлено-29.09.2025-1e90ff"></td>
      <td><img src="https://img.shields.io/badge/Норм%20Executor-32cd32"></td>
    </tr>
    <tr>
      <td><b>Xeno</b></td>
      <td>🖥 ПК</td>
      <td><img src="https://img.shields.io/badge/167%2F228-73%25-ffd700"></td>
      <td><img src="https://img.shields.io/badge/43%2F228-18%25-ffa500"></td>
      <td><img src="https://img.shields.io/badge/Обновлено-29.09.2025-1e90ff"></td>
      <td><img src="https://img.shields.io/badge/Подделывают%20некоторые%20функции%2C%20но%20неплохо%20для%20Level%203-ffd700"></td>
    </tr>
    <tr>
      <td><b>Velocity</b></td>
      <td>🖥 ПК</td>
      <td><img src="https://img.shields.io/badge/Крашится-ff0000"></td>
      <td><img src="https://img.shields.io/badge/Нет%20данных-lightgrey"></td>
      <td><img src="https://img.shields.io/badge/Обновлено-08.09.2025-1e90ff"></td>
      <td><img src="https://img.shields.io/badge/Парашный%20инжектор%20боже%20%F0%9F%A4%AC%F0%9F%A4%AC%F0%9F%A4%AC%F0%9F%A4%AC-ff0000"></td>
    </tr>
    <tr>
      <td><b>KRNL</b></td>
      <td>📱 Мобильный</td>
      <td><img src="https://img.shields.io/badge/Крашится-ff0000"></td>
      <td><img src="https://img.shields.io/badge/Нет%20данных-lightgrey"></td>
      <td><img src="https://img.shields.io/badge/Обновлено-08.09.2025-1e90ff"></td>
      <td><img src="https://img.shields.io/badge/Крашится-critical"></td>
    </tr>
    <tr>
      <td><b>JJSploit</b></td>
      <td>🖥 ПК</td>
      <td><img src="https://img.shields.io/badge/140%2F208-67%25-ffd700"></td>
      <td><img src="https://img.shields.io/badge/46%2F208-22%25-ffa500"></td>
      <td><img src="https://img.shields.io/badge/Обновлено-08.09.2025-1e90ff"></td>
      <td><img src="https://img.shields.io/badge/Потомок%20Xeno-ffd700"></td>
    </tr>
    <tr>
      <td><b>Seliware</b></td>
      <td>🖥 ПК</td>
      <td><img src="https://img.shields.io/badge/311%2F330-94%25-00ff99"></td>
      <td><img src="https://img.shields.io/badge/16%2F330-4%25-00ff99"></td>
      <td><img src="https://img.shields.io/badge/Обновлено-29.09.2025-1e90ff"></td>
      <td><img src="https://img.shields.io/badge/Ахуенный%20инжектор❤️‍🔥-00ff99"></td>
    </tr>
    <tr>
      <td><b>Sirhurt</b></td>
      <td>🖥 ПК</td>
      <td><img src="https://img.shields.io/badge/Крашится-ff0000"></td>
      <td><img src="https://img.shields.io/badge/Нет%20данных-lightgrey"></td>
      <td><img src="https://img.shields.io/badge/Обновлено-11.09.2025-1e90ff"></td>
      <td><img src="https://img.shields.io/badge/Крашится-critical"></td>
    </tr>
    <tr>
      <td><b>Neverfall</b></td>
      <td>🖥 ПК</td>
      <td><img src="https://img.shields.io/badge/Ожидаются%20результаты-lightgrey"></td>
      <td><img src="https://img.shields.io/badge/Ожидаются%20данные-lightgrey"></td>
      <td><img src="https://img.shields.io/badge/Заебали%20когда%20обновление-lightgrey"></td>
      <td><img src="https://img.shields.io/badge/Нет%20данных-lightgrey"></td>
    </tr>
    <tr>
      <td><b>Nucleus</b></td>
      <td>🖥 ПК</td>
      <td><img src="https://img.shields.io/badge/264%2F291-90%25-00ff99"></td>
      <td><img src="https://img.shields.io/badge/21%2F291-7%25-00ff99"></td>
      <td><img src="https://img.shields.io/badge/Обновлено-13.09.2025-1e90ff"></td>
      <td><img src="https://img.shields.io/badge/Отличный%20Executor%2C%20рекомендуется%2C%20но%20обнаружается%20ROBLOX-32cd32"></td>
    </tr>
    <tr>
    <td><b>Zenith</b></td>
      <td>🖥 ПК</td>
      <td><img src="https://img.shields.io/badge/315%2F340-92%25-00ff99"></td>
      <td><img src="https://img.shields.io/badge/19%2F340-5%25-00ff99"></td>
      <td><img src="https://img.shields.io/badge/Обновлено-28.09.2025-1e90ff"></td>
      <td><img src="https://img.shields.io/badge/Отличный%20инжектор%20с%20кастомными%20функциями%20(НО%2C%20легко%20задетектить%20через%20поведение%20сборщика%20мусора)-32cd32"></td>
    </tr>
  </tbody>
</table>
