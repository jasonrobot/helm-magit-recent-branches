;;; -*- lexical-binding: t; -*-
;;; magit-helm-recent-branches --- Summary
;; Use helm to select a recent branch to switch to.

;;; Commentary:
;; I've wanted this for a while now in Emacs.  Currently everything's a bit
;; hard-coded.  I should look in to using some customs for things.
;; Uses magit's faces for colors, so it should look consistent with magit,
;; and most themes should define those.

;; This doesn't actually need dash and s, but it does help keep some of
;; the code better organized, and I wanted to try them out.

;;; Code:

(require 'dash)
(require 's)
(require 'subr-x)

(defun build-helm-candidate (line)
  "Make a helm candidate for recent-branches from LINE."
  (let* ((branch-name (propertize (elt line 0)
                                  'face 'magit-branch-remote))
         (commit-date (propertize (elt line 1)
                                  'face 'magit-log-date))
         (commit-message (elt line 2))
         (message-length (- (window-body-width)
                            (length branch-name)
                            (length commit-date)
                            ;; length of " - " twice, plus some for the window width
                            12)))
    (format "%s - %s - %s"
            branch-name
            ;; truncate commit message if necessary
            (if (> (length commit-message) message-length)
                (format "%s..." (s-left (- message-length 3) commit-message))
              commit-message)
            commit-date)))

(defun remove-current-branch-marker-column (line)
  "Remove the column of the git output that indicates the current branch.
Our git output will include a column in each LINE that we use to filter out
the current branch.  After we remove it, it will be empty in all lines, so
remove the first element."
  (--map (seq-drop (split-string it ";") 1) line))

(defun remove-current-branch-from-lines (lines)
  "Remove the current branch from LINES."
  (--reject (s-equals? "*" (s-left 1 it)) lines))

(defun helm-magit-recent-branches ()
  "Get recent git branches."
  (interactive)
  (let* ((git-output (shell-command-to-string "git for-each-ref --sort='-committerdate' refs/heads/ --format='%(HEAD);%(refname:short);%(committerdate:relative);%(contents:subject)'"))
         ;; turn the output of the git command into a list of strings to build helm candidates from
         (git-output-lines (-> git-output
                               (s-trim)
                               (s-lines)
                               (remove-current-branch-from-lines)
                               (remove-current-branch-marker-column)))
         ;; get the list of branch names
         (branch-names (-map 'car git-output-lines))
         ;; format that into a nice thing we can show the user - we'll be matching of the index later
         (helm-candidates (-map 'build-helm-candidate git-output-lines))
         ;; do the helm thing and get the result
         (helm-selection (helm :sources
                               (helm-build-sync-source "recent branches"
                                 :candidates helm-candidates
                                 :fuzzy-match nil)
                               :buffer "*magit recent branches*"))
         ;; the index of their helm selection is the index of the branch name we want
         (selected-branch (when helm-selection
                            (->> helm-candidates
                                 (--find-index (s-equals? it helm-selection))
                                 (elt branch-names)))))
    ;; checkout that branch
    (when selected-branch
      (magit-checkout selected-branch))))

(provide 'magit-helm-recent-branches)
;;; helm-magit-recent-branches.el ends here

