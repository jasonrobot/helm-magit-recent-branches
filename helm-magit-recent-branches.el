;;; magit-helm-recent-branches --- Summary
;; Use helm to select a recent branch to switch to.

;;; Commentary:
;; I've wanted this for a while now in Emacs.

;;; Code:

(require 'dash)
(require 's)
(require 'subr-x)

(defun build-helm-candidate (line)
  "Make a helm candidate for recent-branches from LINE."
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

(defun remove-current-branch-marker-column (line)
  "Our git output will include a column in each LINE that we use to filter out the current branch.  After we remove it, it will be empty in all lines, so remove the first element."
  (--map (seq-drop (split-string it ";") 1) line))

(defun remove-current-branch-from-lines (lines)
  "Remove the current branch from LINES."
  (--reject (s-equals? "*" (car it)) lines))

(defun helm-magit-recent-branches ()
  "Get recent git branches."
  (interactive)
  (let* ((git-output (shell-command-to-string "git for-each-ref --sort='-committerdate' refs/heads/ --format='%(HEAD);%(refname:short);%(contents:subject);%(committerdate:relative)' | head -n 50"))
         ;; trim, split the command output into lines, split the lines into tokens, remove the current branch
         (git-output-lines (-> git-output
                               (s-trim)
                               (s-lines)
                               (remove-current-branch-from-lines)
                               (remove-current-branch-marker-column)))
         ;; get the list of the commit hashes
         (branch-names (--map 'car git-output-lines))
         ;; format that into a nice thing we can show the user - we'll be matching of the index later
         (helm-candidates (-map 'build-helm-candidate git-output-lines))
         ;; do the helm thing and get the result
         (helm-selection (helm :sources
                               (helm-build-sync-source "recent branches"
                                 :candidates helm-candidates
                                 :fuzzy-match nil)
                               :buffer "*magit recent branches*"))
         ;; the index of their helm selection is the index of the commit hash we want
         (selected-commit (elt branch-names (--find-index (s-equals? it helm-selection) helm-candidates))))
    ;; checkout that commit
    (magit-checkout selected-commit)))

(provide 'magit-helm-recent-branches)
;;; magit-helm-recent-branches.el ends here

