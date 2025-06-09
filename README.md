# PHP Laravelフレームワーク 「投稿アプリ」 
 

* Demonstration Site 
    - https://vd3baeky.infinityfreeapp.com/

* Docker-Hub : vd3baeky/renderoutput_php_laravel
    - https://hub.docker.com/v2/namespaces/vd3baeky/repositories/renderoutput_php_laravel/tags
 
* This Repository
    - https://github.com/VD3baeKy/RenderOutput_PHP_Laravel.git

---
## 1. Laravel をインストールする

* インストールが正常に完了すると、"Laravelウェルカムページ"が表示される。

![image](https://github.com/user-attachments/assets/3244e3d4-763e-4a85-bbb2-7823c2edad60)
 
---

## 2. アプリの配置方法
* Laravelアプリは、```/htdocs```ディレクトリへ配置する。
 
---

## 3. ```Vite manifest not found at: ./public/build/manifest.json```エラー
* ```/public/build/manifest.json```ファイルを確認する。
* ```/public/build/manifest.json```ファイルがある場合は、アクセス権限を確認する。
* ```/public/build/manifest.json```ファイルがない場合は、```/build```ディレクトリを```/public```ディレクトリへ配置する。
* もしも、```/build```ディレクトリがない場合は、**プロジェクトのルートディレクトリ**でアセットをビルド（```npm run build```）して作成する。

![image](https://github.com/user-attachments/assets/52730a92-69dd-4f96-a71b-32bdeaf8577f) 

---

### ※ ```vendor```ディレクトリ、```autoload.php```
* **プロジェクトのルートディレクトリ**で```composer install```を実行して依存関係をインストールすると作成される。
``` bash
composer install
```
 
---
## 4.  ```app_key```
* ```app_key```が設定されていない場合、```.env```ファイルへ設定する。 

![image](https://github.com/user-attachments/assets/074ff161-0ab1-47b1-b7e1-418561c6b32f) 
 
---
## 5-1. Laravel WEBアプリ 「投稿アプリ」 ：ログインページ
![image](https://github.com/user-attachments/assets/96df4fe0-e7b0-4d19-a5ff-c4c5265185bb) 

---
## 5-2. Laravel WEBアプリ 「投稿アプリ」 ：投稿一覧ページ
![image](https://github.com/user-attachments/assets/b6b46ac1-b8fc-4f25-94ea-11bb1e07fa1b) 

---
## 5-3. Laravel WEBアプリ 「投稿アプリ」 ：新規投稿ページ
![image](https://github.com/user-attachments/assets/33815d04-5394-4e00-80c0-cf511e72f8b7) 

---
## 5-4. Laravel WEBアプリ 「投稿アプリ」 ：投稿編集ページ
![image](https://github.com/user-attachments/assets/cfae3526-2e25-4ed4-a7bc-4c3779706619) 

---
## 5-5. Laravel WEBアプリ 「投稿アプリ」 ：投稿詳細ページ
![image](https://github.com/user-attachments/assets/8bce2139-519c-458b-ae08-b78cd4a66874) 

---
## 6. Class Hierarchy
![image](https://github.com/user-attachments/assets/d8b99183-5695-4025-ac9f-a20fcd5355fe) 
 




