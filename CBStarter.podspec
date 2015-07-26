Pod::Spec.new do |s|

# 1
s.platform = :ios
s.ios.deployment_target = '8.0'
s.name = "CBStarter"
s.summary = "CBStarter contains the necessary files for a basic CB project."
s.requires_arc = true

# 2
s.version = "0.1.0"

# 3
s.license = { :type => "MIT", :file => "LICENSE" }

# 4 - Replace with your name and e-mail address
s.author = { "Marcus Broome" => "marcusbroome@me.com" }

# For example,
# s.author = { "Joshua Greene" => "jrg.developer@gmail.com" }


# 5 - Replace this URL with your own Github page's URL (from the address bar)
s.homepage = "https://github.com/marcuzb/CBStarter"

# For example,
# s.homepage = "https://github.com/JRG-Developer/CBStarter"


# 6 - Replace this URL with your own Git URL from "Quick Setup"
s.source = { :git => "[Your CBStarter Git URL Goes Here]", :tag => "#{s.version}"}

# For example,
# s.source = { :git => "https://github.com/marcuzb/CBStarter.git", :tag => "#{s.version}"}


# 7
s.framework = "UIKit"

# 8
s.source_files = "CBStarter/**/*.{swift}"

# 9
s.resources = "CBStarter/**/*.{png,jpeg,jpg,storyboard,xib}"
end