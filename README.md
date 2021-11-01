![](./Jekyll-Zip-Bundler-Logo.png)

# jekyll-zip-bundler
Jekyll plugin which bundles files in a zip archive

## Usage
Rubyzip is needed:
```
~ gem 'rubyzip', '~>2.3.0'
```
These are some examples how you use the liquid tag:
```
{% zip archiveToCreate.zip file1.txt file2.txt %}
{% zip archiveToCreate.zip file1.txt folder/file2.txt 'file with spaces.txt' %}
{% zip {{ variableName }} file1.txt 'folder/file with spaces.txt' {{ otherVariableName }} %}
{% zip {{ variableName }} {{ VariableContainingAList }} %}
```
