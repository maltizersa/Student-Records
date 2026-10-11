# Student Records (Activity 4: CRUD with REST API)

A responsive Flutter app that does CRUD on students through the provided PHP REST API (XAMPP).

## How to use

| Action | Gesture |
| --- | --- |
| **List** | Opens on launch. Pull down or tap the refresh button to reload. |
| **Search** | Type a name or Student ID in the search box. |
| **View** | Tap a student card. |
| **Add** | Tap the floating **Add Student** button. |
| **Edit** | Swipe a card from right to left. |
| **Delete** | Press and hold a card, then confirm. |

The details screen also has **Edit** and **Delete** buttons.

## Setup

1. Copy the `php_api_sample` folder into `C:\xampp\htdocs\`.
2. Start **Apache** and **MySQL** in the XAMPP Control Panel.
3. In phpMyAdmin, create the database `api_db` and import `database/api_db.sql`.
4. If your MySQL password is different, edit `api/db.php`.
5. Run the app:

   ```bash
   flutter pub get
   flutter run
   ```

### API URL

Set in [lib/config/api_config.dart](lib/config/api_config.dart):

- Android emulator: `http://10.0.2.2/php_api_sample/api/student` (`10.0.2.2` is your PC's localhost)
- Windows desktop: `http://localhost/php_api_sample/api/student`
- Real phone on the same Wi-Fi: use your PC's IP address:

  ```bash
  flutter run --dart-define=API_URL=http://192.168.1.5/php_api_sample/api/student
  ```

> Flutter **web** (Chrome) won't work because the PHP API doesn't send CORS headers. Use Android or Windows.

## API verification (curl)

Run these in Git Bash and screenshot the output for the deliverable. `-i` shows the status code.

```bash
curl -i http://localhost/php_api_sample/api/student
```

```bash
curl -i http://localhost/php_api_sample/api/student/4
```

```bash
curl -i -X POST http://localhost/php_api_sample/api/student -H "Content-Type: application/json" -d '{"first_name":"Juan","last_name":"Dela Cruz","age":18}'
```

```bash
curl -i -X PUT http://localhost/php_api_sample/api/student/4 -H "Content-Type: application/json" -d '{"age":23}'
```

```bash
curl -i -X DELETE http://localhost/php_api_sample/api/student/18
```

(Use an ID returned by the POST for the DELETE.)

## Project structure

```
lib/
  main.dart                       App entry and theme
  config/api_config.dart          API base URL
  models/student.dart             Student model + JSON parsing
  services/student_api.dart       GET/POST/PUT/DELETE (async/await + try/catch)
  services/api_exception.dart     User-friendly error messages
  utils/validators.dart           Client-side form validation
  screens/student_list_screen.dart    List, refresh, swipe/hold/tap gestures
  screens/student_detail_screen.dart  View one student (handles 404)
  screens/student_form_screen.dart    Add / edit form
  widgets/                        Card, avatar, delete dialog, feedback views
test/                             API, validator and widget tests
```

Run tests with `flutter test`.
