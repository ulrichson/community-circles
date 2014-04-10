# For an explanation of the steroids.config properties, see the guide at
# http://guides.appgyver.com/steroids/guides/project_configuration/config-application-coffee/

steroids.config.name = "Community Circles Mobile"

# -- Initial Location --
# steroids.config.location = "http://localhost/views/login/index.html"

# -- Tab Bar --
steroids.config.tabBar.enabled = true
steroids.config.tabBar.tabs = [
  {
    title: "Map"
    icon: "icons/location@2x.png"
    location: "http://localhost/views/map/index.html"
  },
  # {
  #   title: "Nearby"
  #   icon: "icons/paperplane@2x.png"
  #   location: "http://localhost/views/contribution/index.html?view=nearby"
  # },
  # {
  #   title: "Top"
  #   icon: "icons/star@2x.png"
  #   location: "http://localhost/views/contribution/index.html?view=top"
  # },
  # {
  #   title: "Search"
  #   icon: "icons/search@2x.png"
  #   location: "http://localhost/views/contribution/index.html?view=search"
  # },
  {
    title: "Profile"
    icon: "icons/user@2x.png"
    location: "http://localhost/views/profile/index.html"
  }
]

# steroids.config.tabBar.tintColor = "#00a8b3"
steroids.config.tabBar.tabTitleColor = "#00A8B3"
steroids.config.tabBar.selectedTabTintColor = "#00A8B3"
# steroids.config.tabBar.selectedTabBackgroundImage = "icons/pill@2x.png"

# steroids.config.tabBar.backgroundImage = ""

# -- Navigation Bar --
steroids.config.navigationBar.tintColor = "#00A8B3"
steroids.config.navigationBar.titleColor = "#ffffff"
steroids.config.navigationBar.buttonTintColor = "#ffffff"
steroids.config.navigationBar.buttonTitleColor = "#ffffff"

steroids.config.navigationBar.portrait.backgroundImage = "images/navbar_portrait@2x.png"
# steroids.config.navigationBar.landscape.backgroundImage = "images/navbar_landscape@2x.png"

# -- Android Loading Screen
steroids.config.loadingScreen.tintColor = "#262626"

# -- iOS Status Bar --
steroids.config.statusBar.enabled = true
steroids.config.statusBar.style = "light"

# -- File Watcher --
# steroids.config.watch.exclude = ["www/my_excluded_file.js", "www/my_excluded_dir"]

# -- Pre- and Post-Make hooks --
# steroids.config.hooks.preMake.cmd = "echo"
# steroids.config.hooks.preMake.args = ["running yeoman"]
# steroids.config.hooks.postMake.cmd = "echo"
# steroids.config.hooks.postMake.args = ["cleaning up files"]

# -- Default Editor --
steroids.config.editor.cmd = "subl"
steroids.config.editor.args = ["."]
