;;; init-org.el --- -*- lexical-binding: t -*-
;;
;; Filename: init-org.el
;; Description: Initialize Org, Toc-org, HTMLize, OX-GFM
;; Author: Mingde (Matthew) Zeng
;; Copyright (C) 2019 Mingde (Matthew) Zeng
;; Created: Fri Mar 15 11:09:30 2019 (-0400)
;; Version: 3.0
;; URL: https://github.com/MatthewZMD/.emacs.d
;; Keywords: M-EMACS .emacs.d org toc-org htmlize ox-gfm
;; Compatibility: emacs-version >= 26.1
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;; Commentary:
;;
;; This initializes org toc-org htmlize ox-gfm
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or (at
;; your option) any later version.
;;
;; This program is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs.  If not, see <https://www.gnu.org/licenses/>.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;; Code:

;; ── 跨平台 Org 主目录 ─────────────────────────────
(defconst my-org-root
  (if *sys/win32*
      "D:/org"
    "~/org")
  "Root directory for all Org-related files.")

(defconst my-gtd-dir
  (concat my-org-root "/gtd")
  "Directory for GTD .org files (inbox, projects, etc.).")

(defconst my-roam-dir
  (concat my-org-root "/roam-notes")
  "Directory for Org-roam notes.")

(global-set-key (kbd "C-c l") #'org-store-link)
(global-set-key (kbd "C-c a") #'org-agenda)
(global-set-key (kbd "C-c c") #'org-capture)

;; 创建主目录及子目录（如果不存在）
(dolist (dir (list my-org-root my-gtd-dir my-roam-dir))
  (unless (file-directory-p dir)
    (make-directory dir t)))

(setq org-capture-templates
      `(("t" "Todo" entry (file+headline ,(concat my-gtd-dir "/inbox.org") "TODOs")
         "* TODO %?\n%U\n" :prepend t)
        ("m" "Meeting" entry (file+headline ,(concat my-gtd-dir "/inbox.org") "Meetings")
              "* MEETING with %? :MEETING:\n%U")  
        ("r" "respond" entry (file+headline ,(concat my-gtd-dir "/inbox.org") "Respond")
               "* NEXT Respond to %:from on %:subject\nSCHEDULED: %t\n%U\n%a\n" :clock-in t :clock-resume t :immediate-finish t)
        ("p" "Phone call" entry (file+headline ,(concat my-gtd-dir "/inbox.org") "Calling")
          "* PHONE %? :PHONE:\n%U" :clock-in t :clock-resume t)))

(setq org-todo-keywords
    (quote ((sequence "TODO(t)" "NEXT(n)" "|" "DONE(d)")
            (sequence "WAITING(w@/!)" "HOLD(h@/!)" "|" "MEETING" "CANCELLED(c@/!)" "PHONE"))))


(setq org-refile-targets
      '(("moves.org" :maxlevel . 1)        ; work.org 文件，最多第1级
        ("projects.org" :maxlevel . 2)
))

(setq org-agenda-files (list (concat my-gtd-dir "/moves.org")
                             (concat my-gtd-dir "/inbox.org")
                              (concat my-gtd-dir "/projects.org")))


(setq org-startup-indented t)

;(setq org-agenda-span 'day)

(setq org-todo-state-tags-triggers
      (quote (("CANCELLED" ("CANCELLED" . t))
              ("WAITING" ("WAITING" . t))
              ("HOLD" ("WAITING") ("HOLD" . t))
              (done ("WAITING") ("HOLD"))
              ("TODO" ("WAITING") ("CANCELLED") ("HOLD"))
              ("NEXT" ("WAITING") ("CANCELLED") ("HOLD"))
              ("DONE" ("WAITING") ("CANCELLED") ("HOLD")))))

;; Compact the block agenda view
(setq org-agenda-compact-blocks t)

(defun my/skip-non-toplevel-headlines ()
  "Skip any headline that is not level 2."
  (unless (= (org-current-level) 2)
    (or (outline-next-heading) (point-max))))

(defun my/moves-skipper ()
  "Skip headlines that are either:
  - Not level 2, OR
  - Have a SCHEDULED timestamp."
  (or (my/skip-non-toplevel-headlines)
      (when (org-entry-get nil "SCHEDULED")
        (outline-next-heading)
        (point))))

(setq org-agenda-custom-commands
      '((" " "Daily Agenda with GTD Tracking"
         ((agenda ""
                  ((org-agenda-span 'day)))

          (tags-todo "IBX"
                      ((org-agenda-overriding-header "Tasks to Refile")
                       (org-tags-match-list-sublevels nil)))
          
          (tags-todo "MOVS"
           ((org-agenda-overriding-header "Single-step Tasks")
           (org-agenda-skip-function 'my/moves-skipper)  ; 跳过排期的日程
            (org-tags-match-list-sublevels nil)))

          (tags-todo "PROJ/NEXT"
           ((org-agenda-overriding-header "Project's Next Move")
            (org-tags-match-list-sublevels nil)))

          (tags "PROJ/TODO"
            ((org-agenda-overriding-header "On-Going Projects")
            (org-agenda-skip-function 'my/skip-non-toplevel-headlines)
            (org-tags-match-list-sublevels nil)))

          (tags "PROJ/HOLD"
            ((org-agenda-overriding-header "Stucked Proj.")
            (org-agenda-skip-function 'my/skip-non-toplevel-headlines)
            (org-tags-match-list-sublevels nil)))
))))




(defun my/org-archive-by-tag ()
  "根据标签归档当前子树到同一个文件的不同标题下。
    - Project 标签 -> * Archived Projects
    - Meeting 标签 -> * Archived Meetings  
    - Phone 标签 -> * Archived Phone
    - 其他 -> * Archived Tasks"
  (interactive)
  (let* ((tags (org-get-tags))
         (archive-file (concat my-gtd-dir "/archive.org"))  ; 你的归档文件路径
         (heading
          (cond
           ((member "PROJ" tags) "* Archived Projects")
           ((member "MEETING" tags) "* Archived Meetings")
           ((member "PHONE" tags) "* Archived Phone")
           (t "* Archived Tasks"))))
    ;; 设置归档位置：文件路径::标题
    (setq org-archive-location (concat archive-file "::" heading))
    (org-archive-subtree)))

(with-eval-after-load 'org
  (define-key org-mode-map (kbd "C-c $") #'my/org-archive-by-tag))

; ===========================================================
; 自动将下一个 Project 任务变为 NEXT
; ===========================================================

(defun my/org-auto-mark-next-on-done ()
  "智能自动标记下一个任务为 NEXT，仅当当前任务带有 PROJ 标签时生效"
  (interactive)
  
  (let ((in-agenda (eq major-mode 'org-agenda-mode))
        marker buffer point)
    
    ;; 1. 确定当前上下文
    (cond
     ;; 在 Agenda 视图中
     (in-agenda
      (setq marker (or (org-get-at-bol 'org-marker)
                       (org-agenda-error)))
      (setq buffer (marker-buffer marker))
      (setq point (marker-position)))
     
     ;; 在普通 Org 缓冲区中
     ((derived-mode-p 'org-mode)
      (setq buffer (current-buffer))
      (setq point (point)))
     
     ;; 其他情况
     (t
      (error "不在 Org-mode 或 Agenda 视图中")))
    
    ;; 2. 获取当前任务状态，并检查是否含 PROJ 标签
    (with-current-buffer buffer
      (save-excursion
        (save-restriction
          (widen)
          (goto-char point)
          
          (let ((current-state (org-get-todo-state))
                (current-heading (org-get-heading t t t t))
                (current-level (org-current-level))
                found-next)
            
            ;; 3. 只有在标记为 DONE / CANCELLED 且带有 PROJ 标签时才执行
            (when (and (member current-state '("DONE" "CANCELLED" "DONE(d)"))
                       (member "PROJ" (org-get-tags)))
              
              ;; 4. 移动到当前标题末尾
              (org-end-of-subtree)
              
              ;; 5. 查找下一个同级 TODO 任务
              (while (and (not found-next)
                          (outline-next-heading))
                (let ((level (org-current-level))
                      (todo-state (org-entry-get (point) "TODO")))
                  
                  (cond
                   ;; 找到同级 TODO 任务
                   ((and (<= level current-level)
                         (equal todo-state "TODO"))
                    (setq found-next t)
                    (org-todo "NEXT")
                    
                    ;; 显示消息
                    (if in-agenda
                        (message "✓ Agenda: '%s' [PROJ] 已完成，下一个任务 '%s' 已标记为 NEXT"
                                 current-heading
                                 (org-get-heading t t t t))
                      (message "✓ '%s' [PROJ] 已完成，下一个任务 '%s' 已标记为 NEXT"
                               current-heading
                               (org-get-heading t t t t))))
                   
                   ;; 遇到更高级别的标题，停止搜索
                   ((< level current-level)
                    (setq found-next t))
                   
                   ;; 其他情况继续搜索
                   (t nil))))
              
              ;; 6. 如果没有找到下一个 TODO 任务
              (unless found-next
                (if in-agenda
                    (message "✓ Agenda: '%s' [PROJ] 已完成，没有找到下一个 TODO 任务" 
                             current-heading)
                  (message "✓ '%s' [PROJ] 已完成，没有找到下一个 TODO 任务" 
                           current-heading))))))))))
;; 4. 添加到两个钩子
(add-hook 'org-after-todo-state-change-hook 'my/org-auto-mark-next-on-done)
(add-hook 'org-agenda-after-todo-state-change-hook 'my/org-auto-mark-next-on-done)

; org 打开文件默认折叠
(setq org-startup-folded 'overview)

(if *sys/win32*
    (setq temporary-file-directory "C:/Users/ChangHao/AppData/Local/Temp"))

(defun my/org-download-method (link) 
  (let ((filename
          (file-name-nondirectory
          (car (url-path-and-query
                (url-generic-parse-url link)))))
        (dirname (concat "./img/" (file-name-sans-extension (file-name-nondirectory (buffer-file-name))))))
    (setq org-download-image-dir dirname)
    (make-directory dirname t)
    (expand-file-name (funcall org-download-file-format-function filename) dirname)))


(defun my/org-download-clipboard-windows ()
  (interactive)
  (let ((filename (expand-file-name "screenshot.png" temporary-file-directory)))
    (shell-command-to-string (format "magick clipboard: %s" filename))
    (when (file-exists-p filename)
      (org-download-image filename)
      (delete-file filename))))

(defun my/org-download-clipboard ()
  (interactive)
  (cond (*sys/win32* (my/org-download-clipboard-windows))
        ;(my/is-WSL (my/org-download-clipboard-WSL))
        (t (org-download-clipboard)))) ; for Linux system

(use-package org-download
    :custom
    (org-download-heading-lvl 1) ; 以一级标题作为图片文件夹
    (org-download-method #'my/org-download-method)
    :after org
    :bind (:map org-mode-map
                ("C-c i y" . org-download-yank)
                ("C-c i d" . org-download-delete)
                ("C-c i e" . org-download-edit)
                ("C-M-y" . my/org-download-clipboard)))

(setq org-log-done 'time)

(use-package org
  :after tex  ; 在 tex 包加载之后再加载 org（确保 LaTeX 相关功能可用）
  :init
  (setq org-startup-indented t)  ; 这个变量专门控制 org-indent-mode 的启动
  :hook ((org-mode . org-cdlatex-mode) ; 在进入 org-mode 时自动启用 cdlatex-mode，方便快速输入 LaTeX 公式
        )

  :custom
  ;; ────────────────────────────────
  ;; LaTeX 与公式显示相关设置
  ;; ────────────────────────────────
  (org-highlight-latex-and-related '(native latex entities))
  ;; 高亮 Org 文档中的 LaTeX 语法、数学环境和实体（如 \alpha, \beta）

  (org-pretty-entities t)
  ;; 将 LaTeX 实体（如 \alpha, \beta）渲染为漂亮的 Unicode 字符（如 α, β）

  (org-pretty-entities-include-sub-superscripts nil)
  ;; 不对上下标（如 x_1, y^2）进行美化隐藏，保留原始文本形式，便于编辑

  ;; LaTeX 公式预览图像缩放设置（用于 C-c C-x C-l 触发的 LaTeX 预览）
  (my/latex-preview-scale 1.8)
  ;; 自定义变量：LaTeX 预览图片的缩放比例（1.8 倍更清晰）

  (org-format-latex-options
   `(:foreground "default"
     :background "default"
     :scale ,my/latex-preview-scale
     :html-foreground "Black"
     :html-background "Transparent"
     :html-scale ,my/latex-preview-scale
     :matchers ("begin" "$1" "$" "$$" "\\(" "\\[")))
  ;; 设置 LaTeX 公式转图片时的样式参数：
  ;; - 使用默认前景/背景色（避免与主题冲突）
  ;; - 应用自定义缩放比例
  ;; - HTML 导出时使用透明背景
  ;; - 支持的公式匹配模式（包括行内 $...$、$$...$$、\(...\)、\[...\] 和 begin/end 环境）

  ;; 加载自定义 LaTeX 宏包（位于 ~/texmf/tex/latex/ 下的 mysymbol.sty）
  (org-latex-packages-alist '(("" "mysymbol" t)))
  ;; 在导出 PDF 时自动引入 \usepackage{mysymbol}

  ;; ────────────────────────────────
  ;; Org 日常使用增强设置
  ;; ────────────────────────────────
  (org-log-done 'time)
  ;; 在任务状态变为 DONE 时，自动记录完成时间戳

  (calendar-latitude 30.659722)   ;; 设置地理位置纬度（当前为成都）
  (calendar-longitude 104.063333) ;; 设置地理位置经度（当前为成都）
  ;; 用于 M-x `sunrise-sunset` 或在 agenda 中显示日出日落时间

  (org-export-backends '(ascii html icalendar latex md odt))
  ;; 启用的导出后端：纯文本、HTML、日历(ICS)、LaTeX(PDF)、Markdown、ODT（LibreOffice）

  (org-use-speed-commands t)
  ;; 启用速度命令：在 Org buffer 中单按某些字母（如 t、s、d）即可快速操作

  (org-confirm-babel-evaluate nil)
  ;; 执行代码块时不弹出确认提示（注意安全风险，仅限可信文档）

  (org-latex-listings-options '(("breaklines" "true")))
  ;; 使用 listings 宏包时启用自动换行

  (org-latex-listings t)
  ;; 导出 LaTeX 时使用 listings 宏包高亮源代码（而非默认的 verbatim）

  (org-deadline-warning-days 7)
  ;; 提前 7 天在 agenda 中警告即将到期的任务

  (org-agenda-window-setup 'other-window)
  ;; 打开 agenda 时在另一个窗口显示（不覆盖当前 buffer）

  (org-latex-pdf-process
   '("pdflatex -shell-escape -interaction nonstopmode -output-directory %o %f"
     "pdflatex -shell-escape -interaction nonstopmode -output-directory %o %f"))
  ;; 定义 PDF 导出时调用的编译命令（运行两次以解决引用问题）
  ;; 注意：原配置中 "-shelnl-escape" 是拼写错误，已修正为 "-shell-escape"

  :custom-face
  ;; 自定义 Org Agenda 中“当前时间”指示器的颜色
  (org-agenda-current-time ((t (:foreground "spring green"))))
  ;; 使用鲜绿色高亮 agenda 中的当前时刻线

  :config
  ;; ────────────────────────────────
  ;; 运行时配置（非定制变量）
  ;; ────────────────────────────────
  (add-to-list 'org-latex-packages-alist '("" "listings"))
  ;; 显式添加 listings 宏包（与上面的 org-latex-listings 配合使用）




  ;; ────────────────────────────────
  ;; Babel 代码块支持
  ;; ────────────────────────────────
  (org-babel-do-load-languages
   'org-babel-load-languages
   '((C . t)
     (python . t)
     (plantuml . t)))
  ;; 启用指定语言的代码块执行支持：C、Python、PlantUML

  ;; ────────────────────────────────
  ;; 自定义辅助函数
  ;; ────────────────────────────────
  (defun org-export-toggle-syntax-highlight ()
    "临时启用 minted 宏包进行语法高亮，用于高质量 PDF 导出。"
    (interactive)
    (setq-local org-latex-listings 'minted)  ; 使用 minted 替代 listings
    (add-to-list 'org-latex-packages-alist '("newfloat" "minted")))  ; 引入 minted 和 newfloat 宏包

  (defun org-table-insert-vertical-hline ()
    "在当前光标位置插入 #+attr_latex 行，为表格添加垂直线（默认 |c|c|c|，可手动调整）。"
    (interactive)
    (insert "#+attr_latex: :align |c|c|c|"))
  )


(use-package org-modern
  :ensure t
  :hook (after-init . (lambda ()
			(setq org-modern-hide-stars 'leading)
			(global-org-modern-mode t)))
  :config
  ;; 定义各级标题行字符
  (setq org-modern-star ["✜" "○" "✸" "✳" "◈" "◇" "✿" "❀" "✜"])
   (setq-default line-spacing 0.1)
   (setq org-modern-label-border 1)
   (setq org-modern-table-vectical 2)
   (setq org-modern-table-horizontal 0)

  ;; 复选框美化
  (setq org-modern-checkbox
	'((?X . #("▢✓" 0 2 (composition ((2)))))
	  (?- . #("▢–" 0 2 (composition ((2)))))
	  (?\s . #("▢" 0 1 (composition ((1)))))))
  ;; 列表符号美化
  (setq org-modern-list
	'((?- . "•")
	  (?+ . "◦")
	  (?* . "▹")))
  ;; 代码块左边加上一条竖边线
  (setq org-modern-block-fringe t)

  ;; 属性标签使用上述定义的符号，不由 org-modern 定义
  (setq org-modern-block-name nil)
  (setq org-modern-keyword nil)
)


;  :config
;  ;; 自定义 cdlatex 括号插入行为：用 \(...\) 替代 $...$
;  (defun my/insert-inline-OCDL ()
;    "Insert \\( ... \\) for inline math."
;    (interactive)
;    (insert "\\(")
;    (save-excursion (insert "\\)")))
;
;  (defun my/insert-bra-OCDL ()
;    "Insert ( ... )."
;    (interactive)
;    (insert "(")
;    (save-excursion (insert ")")))
;
;  (defun my/insert-sq-bra-OCDL ()   ; 修正原拼写错误：原为 insert-square-bra-OCDL
;    "Insert [ ... ]."
;    (interactive)
;    (insert "[")
;    (save-excursion (insert "]")))
;
;  (defun my/insert-curly-bra-OCDL ()
;    "Insert { ... }."
;    (interactive)
;    (insert "{")
;    (save-excursion (insert "}")))
;
;    (define-key org-cdlatex-mode-map (kbd "$")  'my/insert-inline-OCDL)
;    (define-key org-cdlatex-mode-map (kbd "(")  'my/insert-bra-OCDL)
;    (define-key org-cdlatex-mode-map (kbd "[")  'my/insert-sq-bra-OCDL)
;    (define-key org-cdlatex-mode-map (kbd "{")  'my/insert-curly-bra-OCDL)
;  )

;; 可选：自动切换公式预览（光标进入/离开 LaTeX 片段时自动预览）
(use-package org-fragtog
  :hook (org-mode . org-fragtog-mode))

;; 可选：增强版公式预览（需手动下载或通过 straight 安装）
;; 快速编译数学公式, 测试版
(use-package org-preview
  :load-path "lisp/"
  :straight nil          
  :defer t
  :hook (org-mode . org-preview-mode))
;(use-package org
;  :straight (:type built-in)
;  :defer t
;  :bind (("C-c l" . org-store-link)
;         ("C-c a" . org-agenda)
;         ("C-c c" . org-capture)
;         (:map org-mode-map (("C-c C-p" . eaf-org-export-to-pdf-and-open)
;                             ("C-c ;" . nil))))
;  :custom
;  (org-log-done 'time)
;  (calendar-latitude 30.659722) ;; Prerequisite: set it to your location, currently default: Toronto, Canada
;  (calendar-longitude 104.063333) ;; Usable for M-x `sunrise-sunset' or in `org-agenda'
;  (org-export-backends (quote (ascii html icalendar latex md odt)))
;  (org-use-speed-commands t)
;  (org-confirm-babel-evaluate 'nil)
;  (org-latex-listings-options '(("breaklines" "true")))
;  (org-latex-listings t)
;  (org-deadline-warning-days 7)
;  (org-todo-keywords
;   '((sequence "TODO" "IN-PROGRESS" "REVIEW" "|" "DONE" "CANCELED")))
;  (org-agenda-window-setup 'other-window)
;  (org-latex-pdf-process
;   '("pdflatex -shelnl-escape -interaction nonstopmode -output-directory %o %f"
;     "pdflatex -shell-escape -interaction nonstopmode -output-directory %o %f"))
;  :custom-face
;  (org-agenda-current-time ((t (:foreground "spring green"))))
;  :config
;  (add-to-list 'org-latex-packages-alist '("" "listings"))
;  (unless (version< org-version "9.2")
;    (require 'org-tempo))
;  (when (file-directory-p "~/org/agenda/")
;    (setq org-agenda-files (list "~/org/agenda/")))
;  (org-babel-do-load-languages
;   'org-babel-load-languages
;   '(;; other Babel languages
;     (C . t)
;     (python . t)
;     (plantuml . t)))
;  (defun org-export-toggle-syntax-highlight ()
;    "Setup variables to turn on syntax highlighting when calling `org-latex-export-to-pdf'."
;    (interactive)
;    (setq-local org-latex-listings 'minted)
;    (add-to-list 'org-latex-packages-alist '("newfloat" "minted")))
;
;  (defun org-table-insert-vertical-hline ()
;    "Insert a #+attr_latex to the current buffer, default the align to |c|c|c|, adjust if necessary."
;    (interactive)
;    (insert "#+attr_latex: :align |c|c|c|")))
;; -OrgPac

(use-package org-roam
            :ensure t ;; 自动安装
            :custom
            (org-roam-directory my-roam-dir) ;; 默认笔记目录, 提前手动创建好
            (org-roam-dailies-directory "daily/") ;; 默认日记目录, 上一目录的相对路径
            (org-roam-db-gc-threshold most-positive-fixnum) ;; 提高性能
            :bind (("C-c n f" . org-roam-node-find)
                   ;; 如果你的中文输入法会拦截非 ctrl 开头的快捷键, 也可考虑类似如下的设置
                   ;; ("C-c C-n C-f" . org-roam-node-find)
                   ("C-c n i" . org-roam-node-insert)
                   ("C-c n c" . org-roam-capture)
                   ("C-c n l" . org-roam-buffer-toggle) ;; 显示后链窗口
                   ("C-c n u" . org-roam-ui-mode)) ;; 浏览器中可视化
            :bind-keymap
            ("C-c n d" . org-roam-dailies-map) ;; 日记菜单
            :config
            (require 'org-roam-dailies)  ;; 启用日记功能
            (org-roam-db-autosync-mode)) ;; 启动时自动同步数据库

(use-package org-roam-ui
  :ensure t ;; 自动安装
  :after org-roam
  :custom
  (org-roam-ui-sync-theme t) ;; 同步 Emacs 主题
  (org-roam-ui-follow t) ;; 笔记节点跟随
  (org-roam-ui-update-on-save t))

;; OrgRoamPac
;(use-package org-roam
;  :after org
;  :custom
;  (org-roam-node-display-template
;   (concat "${title:*} "
;           (propertize "${tags:10}" 'face 'org-tag)))
;  (org-roam-completion-everywhere t)
;  :bind
;  (("C-c n l" . org-roam-buffer-toggle)
;   ("C-c n f" . org-roam-node-find)
;   ("C-c n i" . org-roam-node-insert)
;   ("C-c n h" . org-id-get-create))
;  :config
;  (when (file-directory-p "~/Documents/roam")
;    (setq org-roam-directory (file-truename "~/Documents/roam")))
;  (org-roam-db-autosync-mode))
;;; -OrgRoamPac

;; HTMLIZEPac
(use-package htmlize :defer t)
;; -HTMLIZEPac

;; MarkdownModePac
(use-package markdown-mode :defer t)
;; -MarkdownModePac

;; OXGFMPac
(use-package ox-gfm :defer t)
;; -OXGFMPac

;; PlantUMLPac
(use-package plantuml-mode
  :defer t
  :custom
  (org-plantuml-jar-path (expand-file-name "~/tools/plantuml/plantuml.jar")))
;; -PlantUMLPac

;; PolymodePac
(use-package polymode)

(provide 'init-org)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; init-org.el ends here
