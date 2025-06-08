Demonstration Site 

* https://vd3baeky.infinityfreeapp.com/

---

# Laravel

## 1. Laravel をインストールする

* インストールが正常に完了すると、"Laravelウェルカムページ"が表示される。

![image](https://github.com/user-attachments/assets/3244e3d4-763e-4a85-bbb2-7823c2edad60)
 

## 2. アプリの配置方法
* Laravelアプリは、```/htdocs```ディレクトリへ配置する。
 

## 3. ```Vite manifest not found at: ./public/build/manifest.json```エラー
* ```/public/build/manifest.json```ファイルを確認する。
* ```/public/build/manifest.json```ファイルがある場合は、アクセス権限を確認する。
* ```/public/build/manifest.json```ファイルがない場合は、```/build```ディレクトリを```/public```ディレクトリへ配置する。
* もしも、```/build```ディレクトリがない場合は、**プロジェクトのルートディレクトリ**でアセットをビルド（```npm run build```）して作成する。

![image](https://github.com/user-attachments/assets/52730a92-69dd-4f96-a71b-32bdeaf8577f) 


### ※ ```vendor```ディレクトリ、```autoload.php```
* **プロジェクトのルートディレクトリ**で```composer install```を実行して依存関係をインストールすると作成される。
``` bash
composer install
```
 


## 4.  ```app_key```
* ```app_key```が設定されていない場合、```.env```ファイルへ設定する。 

![image](https://github.com/user-attachments/assets/074ff161-0ab1-47b1-b7e1-418561c6b32f) 
 

## 5. Laravel WEBアプリ 起動画面
![image](https://github.com/user-attachments/assets/b2a01e47-01c1-4906-99eb-7f35f9528ce9)
