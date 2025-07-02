# まちなか保健室アプリ - 技術ドキュメント

## 概要

このドキュメントサイトは、まちなか保健室アプリの技術仕様と開発ガイドラインを提供します。

## ファイル構成

```
docs/
├── index.html          # メインドキュメントページ
├── styles.css          # スタイルシート
├── script.js           # インタラクティブ機能
└── README.md           # このファイル
```

## 開発者向け情報

### 技術スタック
- **フロントエンド**: HTML5, CSS3, JavaScript (ES6+)
- **デザイン**: レスポンシブデザイン, モダンUI
- **フォント**: Inter (Google Fonts)

### 機能
1. **ナビゲーション**: スムーススクロール対応
2. **レスポンシブ**: モバイル・タブレット・デスクトップ対応
3. **インタラクティブ**: ホバーエフェクト、アニメーション
4. **検索機能**: リアルタイムテキスト検索
5. **コピー機能**: コードブロックのワンクリックコピー
6. **プログレスバー**: スクロール進捗表示

### ローカル開発

1. ローカルサーバーの起動:
```bash
# Python 3を使用
python -m http.server 8000

# Node.jsを使用
npx http-server

# Live Server (VS Code Extension)
# VS Codeで index.html を開き、"Go Live" をクリック
```

2. ブラウザでアクセス:
```
http://localhost:8000
```

### カスタマイズ

#### カラーテーマの変更
`styles.css` の CSS カスタムプロパティを編集:

```css
:root {
    --primary-color: #667eea;
    --secondary-color: #764ba2;
    --accent-color: #4299e1;
    --text-color: #2d3748;
    --bg-color: #fafafa;
}
```

#### セクションの追加
1. `index.html` に新しいセクションを追加
2. ナビゲーションメニューにリンクを追加
3. 必要に応じてスタイルを調整

### デプロイメント

#### GitHub Pages
1. GitHub リポジトリに docs フォルダをプッシュ
2. Settings > Pages で Source を "Deploy from a branch" に設定
3. Branch を "main" と "/docs" に設定

#### Netlify
1. docs フォルダを Netlify にドラッグ&ドロップ
2. 自動的にデプロイされます

#### Vercel
```bash
npx vercel --prod
```

### ブラウザサポート

- Chrome 60+
- Firefox 60+
- Safari 12+
- Edge 79+

### パフォーマンス最適化

- 画像の遅延読み込み対応
- CSS/JS の最小化
- フォントの最適化
- スムーズスクロールとアニメーション

### アクセシビリティ

- キーボードナビゲーション対応
- スクリーンリーダー対応
- 適切なコントラスト比
- セマンティックHTML使用

## ライセンス

このドキュメントサイトは MIT License の下で提供されています。

## 連絡先

技術的な質問やサポートについては、開発チームまでお問い合わせください。
