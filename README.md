# GitLayer (gl)

**Author**: David P. Callanan.

**Version**: 0.1.0.

**How to install**: Ask your AI agent to follow `INSTALL.md`. 

`gl` is a simple command-line utility for managing simultaneous layers of git in your repository. In the same way `.git/info/exclude` separates the working environment from the shared environment's `.gitignore`, GitLayer allows you to separate the working git environment from the shared git environment.

GitHub Copilot has its own diffing layer for AI work (the "working" environment) via a bespoke user interface. Some AI harnesses do not have a nice equivalent, and you are left to use git to manage this workflow. Using git is perfectly fine, and perhaps recommended for professionals who have used git their whole life. The issues lies in that you must overlap this effort into the existing git repository, having no separation between "working" effort and "shared" effort (the actual git history we plan to share with other members of our team). This is as bizarre as including your personal clipboard history or AI log into your commit history that is shared with other team members.

Stashing and other approaches are insufficient (or tedious at best) because AI changes still overlap, causing the collapsing of independent events unless an explicit (usually permanent) commit is created to prevent this. For example, I might have worked effortlessly on `app.js`, writing 100 lines of code by hand. I haven't staged this work yet because I have some other work staged that I am planning to commit independently (e.g. ADHD or multitasking might cause me to be working on a lot simultaneously). I ask AI to fix a typo and it accidentally refactor some critical lines. How do I revert the AI's work? I can't unless I have already explicitly saved my own work in my original shared git layer, even though this shared git layer has nothing to do with my AI work. There is a mixing of concerns, my shared git layer shouldn't need to worry about the fact that I might be doing work outside that layer.

GitLayer solves this by allowing you to create as many independent layers as you want. Ironically, because GitLayer is so focused on separating your working environment from your shared environment, it is not necessarily something you force upon your team. Only team member may want to use GitLayer, just as how another team member might use Vim, or another team member prefers to use WSL over Linux. It does not affect the repo.

# Usage

## `gl`

Type this command on its own to initialize gitlayer. You must be in a git repo to do this, if not, please run `git init` first.

This command can also be used at any point to refresh your environment, which is important. GitLayer alters your environment variables to control how git behaves. If you `cd` into another git repo, you must rerun `gl` to fix your environment, or close your terminal and open a fresh terminal if you want to be in a gl-free environment (todo: implement `gl vamoose` to make the environment gl-free).

## `gl s <layer>` or `gl switch <layer>`

Leave layer blank to switch to the `(default)` layer (the normal `/.git` directory).

Type in an alpha (a-z) name to switch to that layer (ending up in the `/.gitlayer/<name>/.git` directory).

If the layer does not exist, it will be created, equivalent to running `git init`.

You can bounce between layers at any time, there are no restrictions, these are entirely independent views of your codebase. You can work with different layers simultaneously by having multiple terminal sessions open.

Now you can start running any `git` commands you want in the context of this layer!

## `gl s <layer> --copy <original>`

By including another layer to copy from, it will make a verbatim copy of another git layer, e.g. having all the git history.

If you run `gl s <layer> --copy "(default)"`, it will make a copy of the `(default)` layer (i.e. the one in the normal `/.git` directory).

## `gl rm <layer>`

This is a dangerous command as it deletes a layer in its entierty.

## `gl wipe`

Wipes all GitLayer related stuff from this repository.
