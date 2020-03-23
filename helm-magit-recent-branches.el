;;; magit-helm-recent-branches --- Summary
;; Use helm to select a recent branch to switch to.

;;; Commentary:
;; I've wanted this for a while now in Emacs.

;;; Code:

(require 'subr-x)

(defun build-helm-candidates (git-output-lines)
  "Make the helm candidates for recent-branches from GIT-OUTPUT-LINES."
  (mapcar
   (lambda (line)
     (let* ((branch-name (propertize (elt line 0)
                                     'face 'magit-branch-remote))
            (commit-message (elt line 1))
            (commit-date (propertize (elt line 2)
                                     'face 'magit-log-date))
            (message-length (- (window-body-width)
                               (length branch-name)
                               (length commit-date)
                               ;; length of " - " twice, plus some for the window width
                               12)))
       (format "%s - %s - %s"
               branch-name
               (if (> (length commit-message) message-length)
                   (format "%s..." (seq-take commit-message (- message-length 3)))
                 commit-message)
               commit-date)))
   git-output-lines))

(defun helm-magit-recent-branches ()
  "Get recent git branches."
  (interactive)
  (let* ((git-output (shell-command-to-string "git for-each-ref --sort='-committerdate' refs/heads/ --format='%(HEAD);%(refname:short);%(contents:subject);%(committerdate:relative)' | head -n 50"))
         ;; trim, split the command output into lines, split the lines into tokens, remove the current branch
         (git-output-lines (mapcar (lambda (line) (seq-drop (split-string line ";") 1))
                                   (seq-filter (lambda (line) (not (= (string-to-char "*") (elt line 0))))
                                               (split-string (string-trim git-output) "\n"))))
         ;; get the list of the commit hashes
         (branch-names (mapcar (lambda (line) (elt line 0)) git-output-lines))
         ;; format that into a nice thing we can show the user - we'll be matching of the index later
         (helm-candidates (build-helm-candidates git-output-lines))
         ;; do the helm thing and get the result
         (helm-selection (helm :sources (helm-build-sync-source "recent branches"
                                          :candidates helm-candidates
                                          :fuzzy-match nil)
                               :buffer "*magit helm recent branches*"))
         ;; the index of their helm selection is the index of the commit hash we want
         (selected-commit (elt branch-names (cl-position helm-selection helm-candidates :test 'string=))))
    ;; checkout that commit
    (magit-checkout selected-commit)))

(provide 'magit-helm-recent-branches)
;;; magit-helm-recent-branches.el ends here

; magit-branch-remote -  - magit-log-date