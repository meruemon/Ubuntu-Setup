# LaTeX 卒業論文作成ガイド（Overleaf版）

このガイドは、LaTeXを初めて使用する学部生向けに、Overleafを用いて卒業論文を作成するための最低限の知識をまとめたものです。

---

## 1. Overleafの準備

### 1.1 アカウント作成とプロジェクト作成

[Overleaf](https://www.overleaf.com/) にアクセスし、アカウントを作成

### 1.2 プロジェクト構成

テンプレートは以下のような構成になっています：

```
thesis.tex       ← メインファイル（ここからコンパイル）
chap01.tex       ← 第1章（序論）
chap02.tex       ← 第2章
chap03.tex       ← 第3章
chap04.tex       ← 第4章
chap05.tex       ← 第5章（結論）
ref.bib          ← 参考文献データベース
Figs/            ← 図を入れるフォルダ
Style/           ← スタイルファイル
```

**重要**: 各章のファイル（`chap01.tex` など）を編集して論文を書きます。`thesis.tex` は論文のタイトル/名前を記入し、論文を構造を定義するために用いて基本的に触りません。

### 1.3 コンパイル方法

- 左上の「Recompile」ボタンをクリック、または `Ctrl + Enter`（Mac: `Cmd + Enter`）
- 右側にPDFプレビューが表示されます

---

## 2. 文書の構造（章・節の作成）

### 2.1 章（Chapter）

各章ファイルの冒頭に記述します：

```latex
\chapter{序論}
\label{chap:introduction}
```

### 2.2 節（Section）・小節（Subsection）・小小節（Subsubsection）

```latex
\section{本研究の背景}
\label{sec:background}

ここに本文を書きます。

\subsection{推薦システムとは}
\label{subsec:recsys}

小節の本文を書きます。

\subsubsection{協調フィルタリング}

小小節の本文を書きます。
```

### 2.3 ラベルの命名規則（推奨）

| 種類 | プレフィックス | 例 |
|------|--------------|-----|
| 章 | `chap:` | `\label{chap:introduction}` |
| 節 | `sec:` | `\label{sec:background}` |
| 図 | `fig:` | `\label{fig:overview}` |
| 表 | `tab:` | `\label{tab:results}` |
| 式 | `eq:` | `\label{eq:loss}` |

### 2.4 ラベルの参照方法（\ref と \eqref）

`\label` で付けたラベルは `\ref` コマンドで参照できます：

```latex
\ref{ラベル名}
```

**使用例**:

```latex
\ref{chap:introduction}章では研究の背景を述べた。
図\ref{fig:overview}に提案手法の概要を示す。
表\ref{tab:results}に実験結果をまとめる。
\ref{sec:method}節で詳細を説明する。
```

**出力例**:
- 1章では研究の背景を述べた。
- 図3.1に提案手法の概要を示す。
- 表4.2に実験結果をまとめる。
- 3.2節で詳細を説明する。

#### 数式の参照には `\eqref` を使用

数式を参照する場合は、`\ref` ではなく **`\eqref`** を使用してください。`\eqref` は自動的に括弧を付けてくれます：

```latex
% 数式の定義
\begin{equation}
y_{ui} = \mathbf{e}_u^\top \mathbf{e}_i
\label{eq:prediction}
\end{equation}

% 参照（推奨）
式\eqref{eq:prediction}に示すように、予測スコアは内積で計算される。

% 参照（非推奨）
式(\ref{eq:prediction})に示すように...  % 手動で括弧を付ける必要がある
```

**出力の違い**:
| 記述 | 出力 |
|------|------|
| `式\eqref{eq:prediction}` | 式(3.1) ← 自動で括弧付き |
| `式\ref{eq:prediction}` | 式3.1 ← 括弧なし |
| `式(\ref{eq:prediction})` | 式(3.1) ← 手動で括弧 |

**まとめ**:
- 章・節・図・表 → `\ref` を使用
- 数式 → `\eqref` を使用（括弧が自動で付く）

---

## 3. 数式の記述

### 3.1 本文中の数式（インライン数式）

文章の中に数式を入れる場合は `$...$` で囲みます：

```latex
ユーザ$u$とアイテム$i$の予測スコアを$y_{ui}$とする。
温度パラメータ$\tau$は正の実数である。
```

**出力例**: ユーザ *u* とアイテム *i* の予測スコアを *y_ui* とする。

### 3.2 式番号付きの数式（独立行）

`equation` 環境を使用します：

```latex
予測スコアは以下の式で計算される。
\begin{equation}
y_{ui} = \mathbf{e}_u^\top \mathbf{e}_i
\label{eq:prediction}
\end{equation}
式(\ref{eq:prediction})に示すように...
```

**出力例**:  
予測スコアは以下の式で計算される。  
　　　*y_ui = e_u^⊤ e_i*　　　　(3.1)  
式(3.1)に示すように...

### 3.3 式番号なしの独立行数式

`equation*` 環境（アスタリスク付き）を使用します：

```latex
\begin{equation*}
f(x) = ax^2 + bx + c
\end{equation*}
```

### 3.4 複数行の数式（align環境）

複数の式を揃えて表示する場合：

```latex
\begin{align}
\mathbf{e}_{u}^* &= \mathbf{e}_{u} \parallel \bar{\mathbf{e}}_{u} \label{eq:user_rep} \\
\mathbf{e}_{i}^* &= \mathbf{e}_{i} \parallel \bar{\mathbf{e}}_{i} \label{eq:item_rep}
\end{align}
```

- `&` で揃える位置を指定
- `\\` で改行
- 各行に別々のラベルを付けられる

### 3.5 場合分け（cases環境）

```latex
\begin{equation}
w_{ui} = 
\begin{cases}
1 & (p_{ui} \geq \tau) \\
\left(\frac{p_{ui}}{\tau}\right)^\alpha & (p_{ui} < \tau)
\end{cases}
\label{eq:weight}
\end{equation}
```

### 3.6 よく使う数学記号

| 記述 | 出力 | 意味 |
|------|------|------|
| `\sum_{i=1}^{n}` | Σ | 総和 |
| `\prod_{i=1}^{n}` | Π | 総乗 |
| `\frac{a}{b}` | a/b | 分数 |
| `\sqrt{x}` | √x | 平方根 |
| `\mathbf{x}` | **x** | 太字（ベクトル） |
| `\mathcal{L}` | ℒ | 花文字 |
| `\hat{y}` | ŷ | ハット |
| `\bar{x}` | x̄ | バー |
| `\log` | log | 対数 |
| `\exp` | exp | 指数関数 |
| `\partial` | ∂ | 偏微分記号 |
| `\in` | ∈ | 属する |
| `\leq`, `\geq` | ≤, ≥ | 以下、以上 |
| `\cdot` | · | 内積の点 |
| `\times` | × | 掛け算 |
| `\parallel` | ‖ | 連結記号 |

---

## 4. 図の挿入

### 4.1 基本的な図の挿入

```latex
\begin{figure}[t]
    \centering
    \includegraphics[width=0.7\linewidth]{Figs/overview.pdf}
    \caption{提案手法の概要}
    \label{fig:overview}
\end{figure}
```

**各部分の説明**:
- `[t]`: 図の配置位置（t=top, b=bottom, h=here, H=強制的にここ）
- `\centering`: 中央揃え
- `width=0.7\linewidth`: 幅を本文幅の70%に設定
- `Figs/overview.pdf`: 画像ファイルのパス
- `\caption{...}`: 図の説明（「図1: 〜」のように自動で番号が付く）
- `\label{fig:overview}`: 参照用のラベル

### 4.2 図のファイル形式

| 形式 | 推奨度 | 備考 |
|------|-------|------|
| PDF | ◎ | ベクター形式。グラフに最適 |
| PNG | ○ | スクリーンショットなど |
| JPG | △ | 写真向け。文字が荒れやすい |

**推奨**: Pythonのmatplotlibで作成したグラフは `plt.savefig('fig.pdf')` でPDF保存

### 4.3 図の参照

```latex
図\ref{fig:overview}に提案手法の概要を示す。
```

**出力**: 図3.1に提案手法の概要を示す。

### 4.4 横に並べて配置（2つの図）

```latex
\begin{figure}[t]
  \begin{minipage}[b]{0.48\linewidth}
    \centering
    \includegraphics[width=\linewidth]{Figs/result_a.pdf}
    \subcaption{(a) 手法Aの結果}
  \end{minipage}
  \begin{minipage}[b]{0.48\linewidth}
    \centering
    \includegraphics[width=\linewidth]{Figs/result_b.pdf}
    \subcaption{(b) 手法Bの結果}
  \end{minipage}
  \caption{実験結果の比較}
  \label{fig:comparison}
\end{figure}
```

---

## 5. 表の作成

### 5.1 基本的な表

```latex
\begin{table}[t]
\centering
\caption{実験に使用したデータセット}
\label{tab:dataset}
\begin{tabular}{lccc}
\hline
データセット & ユーザ数 & アイテム数 & 相互作用数 \\
\hline
Yelp         & 31,668   & 38,048     & 1,561,406  \\
Amazon-book  & 52,643   & 91,599     & 2,984,108  \\
ML-1M        & 6,040    & 3,706      & 1,000,209  \\
\hline
\end{tabular}
\end{table}
```

**各部分の説明**:
- `{lccc}`: 列の揃え方（l=左, c=中央, r=右）
- `\hline`: 横線
- `&`: 列の区切り
- `\\`: 行の終わり

### 5.2 表の参照

```latex
表\ref{tab:dataset}に実験で使用したデータセットを示す。
```

### 5.3 複数行・複数列のセル

```latex
\usepackage{multirow}  % プリアンブルに追加（thesis.texに既にあり）

\begin{tabular}{lccc}
\hline
\multirow{2}{*}{手法} & \multicolumn{3}{c}{データセット} \\
                      & Yelp & Amazon & ML-1M \\
\hline
手法A & 0.85 & 0.82 & 0.90 \\
手法B & 0.87 & 0.84 & 0.91 \\
\hline
\end{tabular}
```

- `\multirow{2}{*}{手法}`: 2行にまたがるセル
- `\multicolumn{3}{c}{データセット}`: 3列にまたがるセル（中央揃え）

### 5.4 見やすい表（booktabs）

```latex
\begin{tabular}{lccc}
\toprule
手法 & Recall@10 & Recall@20 & NDCG@20 \\
\midrule
LightGCN & 0.0523 & 0.0871 & 0.0412 \\
提案手法 & \textbf{0.0557} & \textbf{0.0941} & \textbf{0.0446} \\
\bottomrule
\end{tabular}
```

- `\toprule`: 太い上線
- `\midrule`: 中間の線
- `\bottomrule`: 太い下線
- `\textbf{...}`: 太字（最良値の強調に）

---

## 6. 参考文献の引用

### 6.1 引用の書き方

```latex
協調フィルタリング~\cite{cf}は代表的な手法である。
複数の文献を引用する場合は~\cite{lightgcn,simgcl}のように書く。
```

**出力**: 協調フィルタリング [1]は代表的な手法である。

#### チルダ（~）を入れる理由

`\cite` の前には **チルダ（`~`）** を入れてください。チルダは「改行されないスペース（非改行スペース）」を意味します。

```latex
% 推奨：チルダあり
協調フィルタリング~\cite{cf}は代表的な手法である。

% 非推奨：チルダなし
協調フィルタリング \cite{cf}は代表的な手法である。
協調フィルタリング\cite{cf}は代表的な手法である。
```

**チルダがない場合の問題**:
- 行末で引用番号だけが次の行に送られてしまう可能性がある
- スペースなしだと文字と引用番号がくっついて見づらい

**悪い例（行末で分断）**:
```
...協調フィルタリング
[1]は代表的な...
```

**良い例（チルダで分断を防止）**:
```
...協調フィルタリング [1]は
代表的な...
```

**覚え方**: 「引用の前はチルダ」→ `~\cite{}`

### 6.2 参考文献の登録（ref.bib）

`ref.bib` ファイルに以下の形式で追加します：

```bibtex
@inproceedings{lightgcn,
  title={LightGCN: Simplifying and Powering Graph Convolution Network for Recommendation},
  author={He, Xiangnan and Deng, Kuan and Wang, Xiang and Li, Yan and Zhang, Yongdong and Wang, Meng},
  booktitle={Proceedings of the 43rd International ACM SIGIR Conference},
  pages={639--648},
  year={2020}
}

@article{cf,
  title={Using Collaborative Filtering to Weave an Information Tapestry},
  author={Goldberg, David and Nichols, David and Oki, Brian M and Terry, Douglas},
  journal={Commun. of the ACM},
  volume={35},
  number={12},
  pages={61--70},
  year={1992}
}
}
```

**ヒント**: IEEE Xplore、ACM Digital Library, Google Scholarで論文を検索し、「引用」→「BibTeX」をクリックすると、この形式でコピーできます。

---

## 7. その他のよく使う機能

### 7.1 箇条書き

**番号なし**:
```latex
\begin{itemize}
    \item 1つ目の項目
    \item 2つ目の項目
    \item 3つ目の項目
\end{itemize}
```

**番号付き**:
```latex
\begin{enumerate}
    \item 第1の手順
    \item 第2の手順
    \item 第3の手順
\end{enumerate}
```

### 7.2 強調

```latex
\textbf{太字にする}
\textit{イタリックにする}
\underline{下線を引く}
```

### 7.3 コメント

```latex
% この行はコメントです（PDFに出力されません）
```

### 7.4 改ページ

```latex
\clearpage  % 改ページして、未配置の図表も出力
\newpage    % 単純な改ページ
```

### 7.5 URLの記載

```latex
\url{https://example.com}
```

---

## 8. よくあるエラーと対処法

### 8.1 コンパイルエラー

| エラー | 原因 | 対処法 |
|--------|------|--------|
| `Missing $ inserted` | 数式モードの不整合 | `$`の数を確認 |
| `Undefined control sequence` | コマンド名のタイプミス | スペルを確認 |
| `Missing \begin{document}` | プリアンブルの問題 | thesis.texを確認 |
| `File not found` | ファイルパスの誤り | パスと拡張子を確認 |
| `Citation undefined` | 参考文献が見つからない | ref.bibの内容を確認 |

### 8.2 図が意図した場所に来ない

図の配置位置オプションを `[H]` にすると強制配置できます：

```latex
\begin{figure}[H]
    ...
\end{figure}
```

**注意**: 多用すると版面が乱れるので、基本は `[t]` や `[b]` を使用

### 8.3 表が横にはみ出る

```latex
\begin{table}[t]
\centering
\caption{...}
\scalebox{0.9}{  % 90%に縮小
\begin{tabular}{...}
...
\end{tabular}
}
\end{table}
```

またはresizeboxを使用すると環境に合わせて調整されます。

```latex
\begin{table}[t]
\centering
\caption{...}
\resizebox{\textwidth}{!} {
\begin{tabular}{...}
...
\end{tabular}
}
\end{table}
```


---

## 9. 執筆のワークフロー

1. **章ごとにファイルを編集**: `chap01.tex`, `chap02.tex`, ... を順番に書く
2. **こまめにコンパイル**: エラーを早期発見するため
3. **図は先にFigsフォルダに**: ファイル名は英数字とアンダースコアのみ推奨
4. **参考文献は随時ref.bibに追加**: 書きながら追加すると楽
5. **最終確認**: 式番号、図表番号、参考文献の参照が正しいか確認

---

## 10. 便利なショートカット（Overleaf）

| 操作 | Windows | Mac |
|------|---------|-----|
| コンパイル | `Ctrl + Enter` | `Cmd + Enter` |
| 保存 | `Ctrl + S` | `Cmd + S` |
| コメントアウト | `Ctrl + /` | `Cmd + /` |
| 検索 | `Ctrl + F` | `Cmd + F` |
| 置換 | `Ctrl + H` | `Cmd + H` |

---

## 付録: 数式サンプル集

### A.1 総和・総乗

```latex
\sum_{i=1}^{N} x_i \quad \prod_{j=1}^{M} y_j
```

### A.2 行列

```latex
\mathbf{A} = \begin{pmatrix}
a_{11} & a_{12} \\
a_{21} & a_{22}
\end{pmatrix}
```

### A.3 ノルム

```latex
\|\mathbf{x}\|_2 \quad \|\mathbf{W}\|_F
```

### A.4 argmax/argmin

```latex
\hat{i} = \argmax_{i \in \mathcal{I}} y_{ui}
```

### A.5 条件付き確率

```latex
p(k|\mathbf{x}, \Theta) = \frac{\pi_k \mathcal{N}(\mathbf{x}|\boldsymbol{\mu}_k, \boldsymbol{\Sigma}_k)}{\sum_{j=1}^{K} \pi_j \mathcal{N}(\mathbf{x}|\boldsymbol{\mu}_j, \boldsymbol{\Sigma}_j)}
```

---

**困ったときは**: 吉田や院生に相談、またはOverleafの[公式ドキュメント](https://www.overleaf.com/learn)を参照してください。
