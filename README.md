## 1. StatefulWidget 與 StatelessWidget 三點差異及實務場景 🏗️

在沒有任何狀態管理套件（如 Provider, Bloc, Riverpod 等）的情況下，`StatefulWidget` 和 `StatelessWidget` 在 Flutter 應用程式中處理 UI 更新和內部資料的方式有以下幾個主要差異：

1.  **內部狀態與生命週期**：
    * **StatelessWidget**：**不包含任何內部狀態**，其配置（屬性）在建立時就確定且不可變。它沒有生命週期方法，只在 `build` 方法中描述 UI。
    * **StatefulWidget**：擁有一組可變的 `State` 物件，這個狀態可以隨著時間或使用者互動而改變。它提供了一系列**生命週期方法**（如 `initState()`, `dispose()` 等），允許開發者在不同階段執行邏輯，例如初始化資料或清理資源。

2.  **重建機制**：
    * **StatelessWidget**：一旦被建立，其 `build` 方法通常只會被呼叫一次，除非其父 Widget 重新構建並傳遞了新的參數。它**本身不會觸發重建**。
    * **StatefulWidget**：可以透過呼叫其 `State` 物件中的 `setState()` 方法來**觸發 UI 重新構建**。當 `setState()` 被呼叫時，Flutter 會重新運行 `build()` 方法，根據新的狀態值更新 UI。

3.  **適用性**：
    * **StatelessWidget**：適用於那些**不依賴於任何外部變化、使用者互動或時間流逝的靜態 UI 片段**。它們的內容一旦渲染就不會改變。
    * **StatefulWidget**：適用於**需要管理內部數據、響應使用者輸入、處理異步操作結果**（如 API 請求），或是需要動態更新 UI 的場景。

---

### 實務場景舉例 🛍️

假設一個**商品詳情畫面**：

* **頁面的標題 (Page Title)**：如果頁面標題在初始化後就固定不變，可以直接使用 **`StatelessWidget`** 搭配 `Text` Widget 完成。
* **商品內容 (Product Content)**：若商品內容（如價格、庫存）是從 API 獲取，且可能每五秒或十秒刷新一次，則這部分內容會使用 **`StatefulWidget`**。每次刷新商品資料時，會呼叫 `setState()` 來觸發 Widget 的生命週期，進而改變並顯示最新的商品內容。

---

## 2. HTTP 與 Dio 套件在網路請求方面的差異 🌐

`http` 和 `dio` 是 Flutter 中常用的兩個網路請求套件，它們在**攔截器、錯誤處理和擴充性**方面有顯著差異：

### Http 套件

`http` 套件是 Dart 官方推薦的基礎 HTTP 客戶端。

1.  **攔截器**：
    * `http` **本身不提供內建的攔截器機制**。
    * 若需實現類似功能（如在請求前添加 Token 或在回應後處理日誌），你必須手動建立一個包裝方法或父類來處理每次網路通訊，或者依賴 `http_interceptor` 等第三方套件來擴充此功能。

2.  **錯誤處理**：
    * `http` 僅包含基本的網路通訊內容和結果。
    * 處理錯誤時，需要**直接使用 `try-catch` 區塊**來捕獲像 `SocketException`（網路連線問題）或檢查 `Response.statusCode`（如 404, 500 等 HTTP 狀態碼）來進行錯誤判斷和處理。它沒有統一的錯誤類型封裝。

3.  **擴充性**：
    * `http` 套件本身實現的功能不多，設計上傾向於輕量化。
    * 擴充方式包括直接使用 `pub.dev` 上針對 `http` 的**擴充套件**，或者透過繼承 `HttpClient` 或 `StreamedRequest` 等底層類別來實現更深層次的自定義邏輯。

---

### Dio 套件

`Dio` 是一個功能強大且高度可配置的 HTTP 客戶端。

1.  **攔截器**：
    * `Dio` **內建了完善的攔截器機制**，封裝了 `onRequest`（請求前）、`onResponse`（回應後）和 `onError`（錯誤發生時）等處理點。
    * 它還支援**重試 (Retry)** 等高級攔截器，極大地簡化了共通邏輯的處理。

2.  **錯誤處理**：
    * `Dio` 提供了**統一的 `DioException` 錯誤類別**來處理各種網路請求問題。
    * `DioException` 包含詳細的錯誤類型（例如 `DioExceptionType.connectionTimeout` 連線超時），使錯誤處理更加清晰和程式化，避免了手動判斷原始 Socket 錯誤或 HTTP 狀態碼。

3.  **擴充性**：
    * `Dio` 的設計考慮到高度擴充性，支援：
        * **自定義 Adapters**：允許使用者自定義請求的發送和回應處理方式。
        * **Transformers**：在請求發送前或接收回應後對資料進行序列化/反序列化。
        * 豐富的**擴充套件生態**：例如 `pretty_dio_logger` 用於美化日誌輸出，提高了開發和調試效率。

---

## 3. Flutter Crash/Error 處理 🐛

在 Flutter 應用程式中，錯誤和崩潰的處理分為局部處理和全局處理兩種層面：

1.  **局部錯誤處理**：
    * 針對**特定的程式碼區塊**中可能發生的、可預期且可恢復的錯誤。
    * 例如，當對**可能為 `null` 的變數進行操作**時，若未經檢查直接使用，會導致運行時錯誤。
    * **處理方式**：
        * **判空檢查**：在操作前使用 `if (variable != null)` 進行檢查。
        * **空安全運算符**：利用 Dart 的 `?.` (條件成員訪問) 或 `??` (空值合併) 運算符來安全地處理可能為 `null` 的值。
        * **`try-catch` 區塊**：用於捕獲程式碼執行時可能拋出的異常（Exceptions），如網路請求失敗、類型轉換錯誤等，並執行恢復邏輯或向用戶提示。

2.  **全局錯誤處理**：
    * 針對應用程式中**未被局部 `try-catch` 捕獲的錯誤**，這些錯誤若不處理會導致應用程式崩潰。
    * **處理方式**：
        * **`FlutterError.onError`**：捕獲 Flutter 框架層的所有未捕獲錯誤。
        * **`PlatformDispatcher.instance.onError`**：用於捕獲 Dart 異步操作中發生的未捕獲錯誤（如 `Future` 錯誤）。
        * **`runZonedGuarded`**：這是 Dart 語言中**最推薦的全局錯誤處理機制**。它能為一段程式碼創建一個「Zone」，並在該 Zone 內部設置統一的錯誤處理程序，有效捕獲幾乎所有同步和異步的未捕獲錯誤。
        * 在捕獲到全局錯誤後，通常會將錯誤資訊（包括堆棧追蹤）發送到**錯誤監控服務**（如 Firebase Crashlytics, Sentry 等），以便在生產環境中進行收集、分析和問題診斷。同時，在生產環境下應向用戶顯示一個友善的錯誤頁面，而不是直接崩潰。


---

## **實作題 UI 範例 ✨**

以下是以 **GetX** 作為狀態管理和路由解決方案的 UI 程式碼範例。GetX 允許我們主要使用 `StatelessWidget` 來構建頁面，避免了傳統 `StatefulWidget` 的狀態疊代複雜性。

* [**main 應用程式入口**](lib/main.dart)
* [**主 UI 畫面**](lib/page/first_page.dart)
* [**控制器**](lib/controller/first_controller.dart)
* [**usecase 業務邏輯**](lib/use_case/get_user_data_use_case.dart)

---

## **資料結構與分層範例 ✨**

此範例採用了清晰的架構分層，使用 **dataclass** 定義資料模型（`Note`、`Tag`、`Note_Tag`）作為資料庫操作的依據。同時，透過宣告**抽象類別**來定義資料操作介面，並在本地與遠端 **repository 實作**中提供具體邏輯。**UseCase** 層則作為業務邏輯的切換入口，有效地隔離了 UI 與資料存取細節。

* [**資料模型 (data class)**](lib/data/)
* [**抽象類別 (interfaces)**](lib/abstract_calss/)
* [**Repository 實作**](lib/repository/)
* [**UseCase 業務邏輯**](lib/use_case/node_repository_use_case.dart)

---

## **功能測試案例 ✨**

為了驗證不同資料來源下的功能正確性，我們設計了針對本地 (Local) 和遠端 (Remote) Repository 的測試。每個 Repository 都包含了其核心的三種功能的測試，確保其在不同環境下的穩定性。

* [**本地 Repository 測試 (3 個 function test success)**](test/local_note_repository_test.dart)
* [**遠端 Repository 測試 (3 個 function test success)**](test/remote_note_repository_test.dart)

---