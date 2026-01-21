;;; init.el --- -*- lexical-binding: t -*-
;;
;; Filename: init.el
;; Description: Initialize M-EMACS
;; Author: Mingde (Matthew) Zeng
;; Copyright (C) 2019 Mingde (Matthew) Zeng
;; Created: Thu Mar 14 10:15:28 2019 (-0400)
;; Version: 3.0
;; URL: https://github.com/MatthewZMD/.emacs.d
;; Keywords: M-EMACS .emacs.d init
;; Compatibility: emacs-version >= 26.1
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;; Commentary:
;;
;; This is the init.el file for M-EMACS
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

;; CheckVer
(cond ((version< emacs-version "26.1")
       (warn "M-EMACS requires Emacs 26.1 and above!"))
      ((let* ((early-init-f (expand-file-name "early-init.el" user-emacs-directory))
              (early-init-do-not-edit-d (expand-file-name "early-init-do-not-edit/" user-emacs-directory))
              (early-init-do-not-edit-f (expand-file-name "early-init.el" early-init-do-not-edit-d)))
         (and (version< emacs-version "27")
              (or (not (file-exists-p early-init-do-not-edit-f))
                  (file-newer-than-file-p early-init-f early-init-do-not-edit-f)))
         (make-directory early-init-do-not-edit-d t)
         (copy-file early-init-f early-init-do-not-edit-f t t t t)
         (add-to-list 'load-path early-init-do-not-edit-d)
         (require 'early-init))))
;; -CheckVer

;; BetterGC
(defvar better-gc-cons-threshold 134217728 ; 128mb
  "The default value to use for `gc-cons-threshold'.

If you experience freezing, decrease this.  If you experience stuttering, increase this.")

(add-hook 'emacs-startup-hook
          (lambda ()
            (setq gc-cons-threshold better-gc-cons-threshold)
            (setq file-name-handler-alist file-name-handler-alist-original)
            (makunbound 'file-name-handler-alist-original)))
;; -BetterGC

;; AutoGC
(add-hook 'emacs-startup-hook
          (lambda ()
            (if (boundp 'after-focus-change-function)
                (add-function :after after-focus-change-function
                              (lambda ()
                                (unless (frame-focus-state)
                                  (garbage-collect))))
              (add-hook 'after-focus-change-function 'garbage-collect))
            (defun gc-minibuffer-setup-hook ()
              (setq gc-cons-threshold (* better-gc-cons-threshold 2)))

            (defun gc-minibuffer-exit-hook ()
              (garbage-collect)
              (setq gc-cons-threshold better-gc-cons-threshold))

            (add-hook 'minibuffer-setup-hook #'gc-minibuffer-setup-hook)
            (add-hook 'minibuffer-exit-hook #'gc-minibuffer-exit-hook)))
;; -AutoGC

;; LoadPath
(defun update-to-load-path (folder)
  "Update FOLDER and its subdirectories to `load-path'."
  (let ((base folder))
    (unless (member base load-path)
      (add-to-list 'load-path base))
    (dolist (f (directory-files base))
      (let ((name (concat base "/" f)))
        (when (and (file-directory-p name)
                   (not (equal f ".."))
                   (not (equal f ".")))
          (unless (member base load-path)
            (add-to-list 'load-path name)))))))

(update-to-load-path (expand-file-name "elisp" user-emacs-directory))
;; -LoadPath

;; Constants

(require 'init-const)

;; Packages

;; Package Management
(require 'init-package)

;; Global Functionalities
(require 'init-global-config)

(require 'init-func)

(require 'init-search)

(require 'init-crux)

(require 'init-avy)

(require 'init-winner)

(require 'init-which-key)

(require 'init-undo-tree)

;(require 'init-discover-my-major)

(require 'init-ace-window)

(require 'init-shell)

(require 'init-dired)

(require 'init-buffer)

;; UI Enhancements
(require 'init-ui-config)

(require 'init-theme)

(require 'init-dashboard)

(require 'init-fonts)

(require 'init-scroll)

;; General Programming
;(require 'init-llm)

(require 'init-magit)

;(require 'init-projectile)

;(require 'init-yasnippet)

(require 'init-dumb-jump)

(require 'init-treesit)

(require 'init-indent)

(require 'init-format)

(require 'init-comment)

(require 'init-edit)

(require 'init-header)

(require 'init-ein)

(require 'init-complete)

;; Programming
;(require 'init-cc)

;(require 'init-python)

;(require 'init-ess)

(require 'init-latex)

;(require 'init-buildsystem)

;; Web Development
;(require 'init-webdev)

;; Office
(require 'init-org)

;; Multimedia
;(require 'init-eaf)

;; Internet

;(require 'init-erc)

;(require 'init-mu4e)

;(require 'init-tramp)

;(require 'init-leetcode)

;(require 'init-debbugs)

;(require 'init-hackernews)

;(require 'init-eww)

;; Miscellaneous
;(require 'init-chinese)
(require 'init-chinese-font)

;; WSL2 下与 Windows 剪贴板互通
(when (and (eq system-type 'gnu/linux)
           (getenv "WSL_DISTRO_NAME"))
  ;; 复制到 Windows 剪贴板
  (defun wsl-copy-to-clipboard ()
    "Copy region to Windows clipboard via clip.exe."
    (interactive)
    (if (region-active-p)
        (let ((text (buffer-substring-no-properties (region-beginning) (region-end))))
          (with-temp-buffer
            (insert text)
            (call-process-region (point-min) (point-max) "/mnt/c/Windows/System32/clip.exe" nil 0)))
      (message "No region selected")))

  ;; 从 Windows 剪贴板粘贴
(defun wsl-paste-from-clipboard ()
  "Paste from Windows clipboard via PowerShell with UTF-8 and ^M cleanup."
  (interactive)
  (let ((text
         ;; 关键：设置控制台输出编码为 UTF-8
         (with-temp-buffer
           (let ((process-environment process-environment))
             ;; 确保 PowerShell 使用 UTF-8
             (setenv "PYTHONIOENCODING" "utf-8") ; 无关但无害
             (call-process "powershell.exe" nil t nil
                           "-Command"
                           "[Console]::OutputEncoding = [System.Text.Encoding]::UTF8; Get-Clipboard")
             (decode-coding-string (buffer-string) 'utf-8-unix)))))
    ;; 清理 ^M 和尾部空白
    (setq text (replace-regexp-in-string "\r" "" text))
    (setq text (string-trim-right text))
    (unless (string-empty-p text)
      (insert text))))


  ;; 绑定快捷键（可选）
(global-set-key (kbd "M-y") #'wsl-paste-from-clipboard)
(global-set-key (kbd "M-c") #'wsl-copy-to-clipboard)

  ;; 可选：让 Emacs 默认的 kill-ring 与 Windows 剪贴板同步
  (defun wsl-kill-ring-save-and-sync (orig-fun &rest args)
    "Save to kill-ring and sync to Windows clipboard."
    (apply orig-fun args)
    (when (region-active-p)
      (wsl-copy-to-clipboard)))
  
  (advice-add 'kill-ring-save :around #'wsl-kill-ring-save-and-sync)
  )

(set-default-coding-systems 'utf-8) ; 默认编码
(set-terminal-coding-system 'utf-8) ; 终端编码
(set-keyboard-coding-system 'utf-8) ; 键盘编码
(prefer-coding-system 'utf-8) ; 首选编码



;; InitPrivate
;; Load init-private.el if it exists
(when (file-exists-p (expand-file-name "init-private.el" user-emacs-directory))
  (load-file (expand-file-name "init-private.el" user-emacs-directory)))
;; -InitPrivate

(provide 'init)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; init.el ends here
