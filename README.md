# Magit Helm Recent Buffers

This is a simple one - a helm command to switch branches in git interactively.

I've got it set to show the last 50 branches, but there's literally no reason for that. Could just show all. I just have it set to do tail -n 50 on the command line.

So ya, for the longest time I had an alias to `git for-each-ref --sort=committerdate refs/heads/ --format='%(HEAD) %(color:yellow)%(refname:short)%(color:reset) - %(color:red)%(objectname:short)%(color:reset) - %(contents:subject) - %(authorname) (%(color:green)%(committerdate:relative)%(color:reset))' | tail -n 50`. It's incredibly useful if you're going back and forth a lot. Then I learned magit, and it was like a whole new world, but I missed `recent-branches`.

Plus, we prefix all our branches at work, so tab completion in magit-checkout is basically useless untill I type in all but the last 4 chars. I really wanted a helm UI for it, so in this time of quarantine I finally went and made one.

I'm gonna use the hell out of this, and if you want it, I hope it improves your workflow.

## Instructions
Bind recent-branches-magit-helm to some key. Then use it. It does exactly what you think.

I bet there are bugs. Hit me up.
