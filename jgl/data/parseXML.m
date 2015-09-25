%Matlab javascript parser
function retval=parseXML(root)
    if (strcmp(root.getTagName, 'val'))
        atr = root.getAttribute('type');
        if (strcmp(atr, 'num'))
            retval = str2double(root.getTextContent);
        else
            retval = char(root.getTextContent);
        end
        return;
    end
    
    if (strcmp(root.getTagName, 'array'))
        atr = char(root.getAttribute('type'));
        if (strcmp(atr, 'mat'))
            retval = [];
        else
            retval = {};
        end
        children = root.getChildNodes;
        for i=0:children.getLength-1
            if (iscell(retval))
                retval{i+1} = parseXML(children.item(i));
            else
                retval(i+1) = parseXML(children.item(i));
            end
        end
        return;
    end
    
    if (strcmp(root.getTagName, 'object'))
        retval = struct();
        children = root.getChildNodes;
        for i=0:children.getLength-1
            child = children.item(i);
            fieldName = char(child.getTagName);
            temp = parseXML(child.getFirstChild);
            eval(sprintf('retval.%s = temp;', fieldName));
        end
        return;
    end
    
    retval = [];
    return;
end