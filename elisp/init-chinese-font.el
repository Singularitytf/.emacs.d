;;; init-chinese.el --- -*- lexical-binding: t -*-
;;
;; Filename: init-chinese.el
;; Description: Initialize Pyim
;; Author: Mingde (Matthew) Zeng
;; Copyright (C) 2019 Mingde (Matthew) Zeng
;; Created: Thu Jun 20 00:36:05 2019 (-0400)
;; Version: 3.0
;; URL: https://github.com/MatthewZMD/.emacs.d
;; Keywords: M-EMACS .emacs.d init
;; Compatibility: emacs-version >= 26.1
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;; Commentary:
;;
;; This initializes pyim and youdao-dictionary suitable for Chinese users.
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

(when *sys/mac*
  (setq fonts '("SF Mono" "冬青黑体简体中文"))
  (set-fontset-font t 'unicode "Apple Color Emoji" nil 'prepend)
  (set-face-attribute 'default nil :font
                      (format "%s:pixelsize=%d" (car fonts) 16)))

(when *sys/win32*
  (setq fonts '("Consolas" "微软雅黑"))
  (set-fontset-font t 'unicode "Segoe UI Emoji" nil 'prepend)
  (set-face-attribute 'default nil :font
                      (format "%s:pixelsize=%d" (car fonts) 16)))

(when (or *sys/wsl* *sys/linux*)
  (setq fonts '("Ubuntu Sans Mono" "Noto Serif CJK SC"))
  (set-fontset-font t 'unicode "Ubuntu Sans Mono" nil 'prepend)
  (set-fontset-font t 'han "Noto Serif CJK SC" nil 'prepend)
  (set-face-attribute 'default nil 
                      :family (car fonts) 
                      :weight 'bold
                      :height 130)) ;; 注意：:height 单位是 1/10 pt，160 约等于 16px

(if (display-graphic-p)
    (dolist (charset '(kana han symbol cjk-misc bopomofo))
      (set-fontset-font (frame-parameter nil 'font) charset
                        (font-spec :family (car (cdr fonts))))))
(provide 'init-chinese-font)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; init-chinese.el ends here
