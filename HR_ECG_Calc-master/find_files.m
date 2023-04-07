function files = find_files(path, file_type)
    % Finds all files of file type 'file_type' at or contained as a 
    % subdirectory of the file system location 'path'. Returns full paths
    % in a string array.
    local_list = dir(path + "/*" + file_type);
    files = [];
    
    % Process any .csv files in the current directory
    for file = 1:length(local_list)
        base = local_list(file).folder; 
        name = local_list(file).name; 
        file_path = base + "\" + name;
        files = [files file_path];
    end
    
    % Continue processing subdirectories
    subdirs = get_subfolders(path);
    for folder = 1:length(subdirs)
        subdir = subdirs(folder);
        files = [files find_files(path + "/" + subdir, file_type)];
    end
end

function folders = get_subfolders(path)
    % Returns a string array containing the names of the current
    % directory's subdirectories.
    
    % make cell array containing names of folders (excluding "." and "..")
    directory = dir(path);
    folder_idxs = [directory.isdir];
    folder_cells = setdiff({directory(folder_idxs).name}, {'.','..'});
    
    % turn cell array into string array
    folders = string(folder_cells);
end
