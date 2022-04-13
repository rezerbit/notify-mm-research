# notify-mm-research

## Быстрое развертывание настроенной среды

```
make up
```

Через примерно 10 секунд в браузере будут доступны

- Mattermost: <http://localhost:8065>

```
email: 
e.musk@mail

password: 
Strong_password2
```

- MockServer: <http://localhost:1080/mockserver/dashboard>

### Завершение работы

```
make down
```

---

## Поднятие локальной инфраструктуры для исследования в docker-контейнерах

Mattermost предлагает запускать в докере

```
docker run --name mattermost-preview -d --publish 8065:8065 mattermost/mattermost-preview
```

При таком подходе не сохраняется состояние и после нового запуска контейнера приходится настраивать канал, бота и вебхук заново.
Поэтому создаем `docker-compose.yml` с отдельным сервисом postgres и томами, хранящими состояние.
Так же в `docker-compose.yml` добавлен мок-сервер для исследования исходящих вебхуков MM.

В качестве mock-сервера можно использовать Postman, но работать с ним не удобно, т.к. логи запросов подгружаются не моментально, а в течении 5 минут. По этой причине отказался от него. Но тестировать API MM с Postman удобно.

## Запуск инфраструктуры

```
mkdir -p ./volumes/app/mattermost/{config,data,logs,plugins,client/plugins,bleve-indexes}
docker-compose up -d
```

- Немного ждем пока настроится MM, смотрим логи:

```
docker logs -f mattermost 
```

- Заходим в браузере, проверяем MM

```
http://localhost:8065/
```

- проверяем mock-сервер

```
localhost:1080/mockserver/dashboard
```

Для отладки можно зайти внутрь контейнера

```
docker exec -ti mattermost /bin/sh 
```

## Первичная настройка MM

- Заполняем форму, создаем аккаунт
![1](images/1.png)

- Создаем команду
![2](images/2.png)

- Завершаем первичную настройку MM

## Добавление и настройка бота

- Создаем канал `notify-test-channel`
![3](images/3.png)

- Переходим в `System Console > Integrations > Bot Accounts`, устанавливаем `Enable Bot Account Creation: true`.

- Переходим в `Integrations > Bot Accounts`
- Жмем `Add Bot account`
- Создаем бота `notify`, выставляем `post:channels: Enabled`
- Получаем и сохраняем Access Token бота (Access Token не то же самое что Token ID, если не сохранили его при создании бота, то позже можно пересоздать через `Create New Token`)
![4](images/4.png)

### Добавление бота в команду

- Кликаем на название команды сверху слева
- `Invite People`
- Пишем в поле To: `notify`
- Выбираем бота
- `Invite`
- `Done`

### Добавление бота в канал

- Кликаем `Add Memebers`
- Вводим `notify`
- Выбираем бота
- Нажимаем `Add`

### Настройка Outgoing Webhook

- Переходим в `Integrations > Outgoing Webhooks > Add Webhook`
- Создаем вебхук notify
- Вписываем колбэк-URL мок-сервера
- Получаем токен вебхука
![5](images/5.png)
![6](images/6.png)

- Т.к. в исследовании используется http протокол, а не https, то нужно разрешить ненадежные соединения, иначе вебхук не сработает, будет ошибка в логах:

```
{"timestamp":"2022-04-13 18:18:47.387 Z","level":"error","msg":"Event POST failed.","caller":"app/webhook.go:119","error":"Post \"http://mock-server:1080\": address forbidden, you may need to set AllowedUntrustedInternalConnections to allow an integration access to your internal network"}
```

- Переходим в `System Console > Environment > Developer`
- Вписываем URL мок-сервера. `Allow untrasted internal connections to: mock-server`

Для дебага можно также смотреть логи MM в `System Console > Reporting > Server Logs`
Также убедитель, что логирование `Webhook Debugging` включено в `System Console > Environment > Logging section` и значение `Log Level` установлено `Debug`.

### Тестирование Outgoing Webhook

- Отправляем в канале `notify`
- ![7](images/7.png)

- Получаем на мок-сервере запрос
![8](images/8.png)

## Настройка Custom Slash Command

Подписки на топики и другие команды боту также можно организовывать через Custom Slash Command.

### Создание команды

- Переходим в `Integrations > Slash Commands`
- Кликаем `Add Slash Command`
- Добавляем команду
![9](images/9.png)
![10](images/10.png)

Для выполнения команды необходимо настроить ответ мок-сервера.
Иначе будет ошибка.
![11](images/11.png)

## Исследование API MM

Чтобы воспользоваться API нужно [авторизоваться](https://api.mattermost.com/#tag/authentication), передав Access Token в заголовке

```
curl -i -H 'Authorization: Bearer <Access Token>' http://localhost:8065/api/v4/users/me
```

Access Token выдается при создании бота.

Получаем ответ

```
HTTP/1.1 200 OK
Content-Type: application/json
Etag: 6.3.7.3u5h894awpn1mm8yw3w5hdrjqe.1649956415437..0.true.true.0
Expires: 0
Vary: Accept-Encoding
X-Request-Id: 5pa36d4ft3noie6g9dshqi4e8h
X-Version-Id: 6.3.7.6.3.7.4017d83cb984e8267e1884bf160d7bf3.false
Date: Thu, 14 Apr 2022 17:15:52 GMT
Content-Length: 767

{
    "id": "3u5h894awpn1mm8yw3w5hdrjqe",
    "create_at": 1649869906885,
    "update_at": 1649956415437,
    "delete_at": 0,
    "username": "notify",
    "auth_data": "",
    "auth_service": "",
    "email": "notify@localhost",
    "nickname": "",
    "first_name": "notify",
    "last_name": "",
    "position": "",
    "roles": "system_user system_post_all_public",
    "notify_props": {
        "channel": "true",
        "comments": "never",
        "desktop": "mention",
        "desktop_sound": "true",
        "desktop_threads": "all",
        "email": "true",
        "email_threads": "all",
        "first_name": "false",
        "mention_keys": "",
        "push": "mention",
        "push_status": "away",
        "push_threads": "all"
    },
    "last_password_update": 1649869906885,
    "locale": "en",
    "timezone": {
        "automaticTimezone": "",
        "manualTimezone": "",
        "useAutomaticTimezone": "true"
    },
    "is_bot": true,
    "bot_description": "A notification bot",
    "disable_welcome_email": false
}
```

### Отправка сообщения

[схема](https://api.mattermost.com/#operation/CreatePost)

Для отправки сообщения нужно знать `chanel_id`. Его можно получить из тела запроса Outgoing Webhook при подписке на топик

```
{
  "method": "POST",
  "path": "/",
  "headers": {
    "content-length": [
      "382"
    ],
    "User-Agent": [
      "Mattermost-Bot/1.1"
    ],
    "Host": [
      "mock-server:1080"
    ],
    "Content-Type": [
      "application/json"
    ],
    "Accept-Encoding": [
      "gzip"
    ],
    "Accept": [
      "application/json"
    ]
  },
  "keepAlive": true,
  "secure": false,
  "body": {
    "token": "rgfe9bc9j3gste59mbyrmzk33w",
    "team_id": "en76g45etjn98c6eyubfptn16o",
    "team_domain": "awesome-team",
    "channel_id": "yuko5hzu7jdcineenpafttbbzw",
    "channel_name": "notify-test-channel",
    "timestamp": 1649958010052,
    "user_id": "a6khpd5m77d3de46xw599mp8by",
    "user_name": "e.musk",
    "post_id": "g19wczuo1byxz86fddtxcin5ec",
    "text": "@notify subscribe TOPIC",
    "trigger_word": "@notify",
    "file_ids": ""
  }
}
```

Отправляем сообщение в канал

```
curl -i -H 'Authorization: Bearer 96d9cy81cbytjydh993py41kuh' -H 'Content-Type: application/json' -d '{"channel_id":"yuko5hzu7jdcineenpafttbbzw","message":"Hi, there!"}' http://localhost:8065/api/v4/posts
```

Получаем

```
HTTP/1.1 201 Created
Content-Type: application/json
Vary: Accept-Encoding
X-Request-Id: 6taukfem1br6jefs7j4qpd5asw
X-Version-Id: 6.3.7.6.3.7.4017d83cb984e8267e1884bf160d7bf3.false
Date: Thu, 14 Apr 2022 17:45:36 GMT
Content-Length: 407

{"id":"u1teeaduyinbjf3n5brjbfoiyw","create_at":1649958336651,"update_at":1649958336651,"edit_at":0,"delete_at":0,"is_pinned":false,"user_id":"3u5h894awpn1mm8yw3w5hdrjqe","channel_id":"yuko5hzu7jdcineenpafttbbzw","root_id":"","original_id":"","message":"Hi, there!","type":"","props":{"from_bot":"true"},"hashtags":"","pending_post_id":"","reply_count":0,"last_reply_at":0,"participants":null,"metadata":{}}
```

![12](images/12.png)

### Отправка сообщения с тэгом пользователя

Иногда требуется отправить сообщение с тэгом пользователя. Если написать в сообщении просто `@e.musk`, то в MM это сработает. Не нужно указывать `user_id`.

```
curl -i -H 'Authorization: Bearer 96d9cy81cbytjydh993py41kuh' -H 'Content-Type: application/json' -d '{"channel_id":"yuko5hzu7jdcineenpafttbbzw","message":"Hi, @e.musk!"}' <http://localhost:8065/api/v4/posts>
````

```
HTTP/1.1 201 Created
Content-Type: application/json
Vary: Accept-Encoding
X-Request-Id: 3imf65r7tpgzzm85jyzicq57gc
X-Version-Id: 6.3.7.6.3.7.4017d83cb984e8267e1884bf160d7bf3.false
Date: Thu, 14 Apr 2022 17:51:56 GMT
Content-Length: 409

{"id":"ae8ynb3kdffytmjor3ggjyu77a","create_at":1649958716333,"update_at":1649958716333,"edit_at":0,"delete_at":0,"is_pinned":false,"user_id":"3u5h894awpn1mm8yw3w5hdrjqe","channel_id":"yuko5hzu7jdcineenpafttbbzw","root_id":"","original_id":"","message":"Hi, @e.musk!","type":"","props":{"from_bot":"true"},"hashtags":"","pending_post_id":"","reply_count":0,"last_reply_at":0,"participants":null,"metadata":{}}
```

![13](images/13.png)

### Получение всех пользователей

[схема](https://api.mattermost.com/#operation/GetUsers)

```
curl -i -H 'Authorization: Bearer 96d9cy81cbytjydh993py41kuh' http://localhost:8065/api/v4/users 
````

```
HTTP/1.1 200 OK
Content-Type: application/json
Expires: 0
Vary: Accept-Encoding
X-Request-Id: nku8cpjybjd69893azpdqsyb4r
X-Version-Id: 6.3.7.6.3.7.4017d83cb984e8267e1884bf160d7bf3.false
Date: Thu, 14 Apr 2022 18:03:57 GMT
Transfer-Encoding: chunked

...
{
    "id": "a6khpd5m77d3de46xw599mp8by",
    "create_at": 1649868427028,
    "update_at": 1649868878984,
    "delete_at": 0,
    "username": "e.musk",
    "auth_data": "",
    "auth_service": "",
    "email": "e.musk@mail",
    "nickname": "",
    "first_name": "e.musk",
    "last_name": "",
    "position": "",
    "roles": "system_admin system_user",
    "locale": "en",
    "timezone": {
      "automaticTimezone": "Asia/Yekaterinburg",
      "manualTimezone": "",
      "useAutomaticTimezone": "true"
    },
    "disable_welcome_email": false
  },
  {
    "id": "3u5h894awpn1mm8yw3w5hdrjqe",
    "create_at": 1649869906885,
    "update_at": 1649956415437,
    "delete_at": 0,
    "username": "notify",
    "auth_data": "",
    "auth_service": "",
    "email": "notify@localhost",
    "nickname": "",
    "first_name": "notify",
    "last_name": "",
    "position": "",
    "roles": "system_user system_post_all_public",
    "locale": "en",
    "timezone": {
      "automaticTimezone": "",
      "manualTimezone": "",
      "useAutomaticTimezone": "true"
    },
    "is_bot": true,
    "bot_description": "A notification bot",
    "disable_welcome_email": false
  },
  ...
```
