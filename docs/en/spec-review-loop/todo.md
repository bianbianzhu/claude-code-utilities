[] deal with re-raised issues in the inner loop - spawn an claude code agent after each codex review to compare the new issue report with the previous one and find out if there are any re-raised issues. - need to notify human reviewer about the re-raised issues and allow human decision to be persisted in the feedback file so it won't be re-raised again
[] human review is needed in the loop - human can easily set a particular issue to be Declined-Accepted in the issue report file so it won't be re-raised again
[] human can set the <promise>ALL_RESOLVED</promise> to control the loop
[] add auto-commit (using a subagent)
[] logic to make issues less and less found by the outer loop
