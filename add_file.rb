require 'xcodeproj'

project_path = 'paws-n-parcels.xcodeproj'
project = Xcodeproj::Project.open(project_path)

group = project.main_group.find_subpath('paws-n-parcels/Engine/Audio', true)
file_path = 'paws-n-parcels/Engine/Audio/SoundManager.swift'

# Avoid duplicates
file_ref = group.files.find { |f| f.path == file_path }
unless file_ref
    file_ref = group.new_reference(file_path)
    # Target index 0 assuming it's the main app target
    target = project.targets.first
    target.add_file_references([file_ref])
    project.save
    puts "Added SoundManager.swift to project"
else
    puts "File already in project"
end
