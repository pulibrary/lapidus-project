xquery version "1.0";

(:~ --------------------------------------------------
    Lapidus controller
    -------------------------------------------------- :)
import module namespace util="http://exist-db.org/xquery/util";

declare namespace exist="http://exist.sourceforge.net/NS/exist";
declare namespace request="http://exist-db.org/xquery/request";

(: These external declarations are not required but make the code
dependency clear. :)

declare variable $exist:root external;
declare variable $exist:prefix external;
declare variable $exist:path external;
declare variable $exist:resource external;
declare variable $exist:controller external;


let $uri:= request:get-uri()
let $context := request:get-context-path()


return
if (request:get-parameter("echo",())) then
   <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
      <forward url="{concat($exist:controller, '/echo.xql')}">
         <add-parameter name="root" value="{$exist:root}"/>
         <add-parameter name="prefix" value="{$exist:prefix}"/>
         <add-parameter name="resource" value="{$exist:resource}"/>
         <add-parameter name="controller" value="{$exist:controller}"/>
         <add-parameter name="context" value="{$context}"/>
         <add-parameter name="path" value="{$exist:path}"/>
         <add-parameter name="pathtokens" value="{tokenize($exist:path, '/')}"/>
         <add-parameter name="url" value="{request:get-url()}"/>
         <add-parameter name="uri" value="{request:get-uri()}"/>
      </forward>
   </dispatch>

else if ($exist:path eq '/') then
<dispatch xmlns="http://exist.sourceforge.net/NS/exist">
  <redirect url="index.html"/>
  <cache-control cache="no"/>
</dispatch>

else if ($exist:resource eq 'display') then
<dispatch xmlns="http://exist.sourceforge.net/NS/exist">
  <forward url="display.xql">
    <set-attribute name="xquery.attribute" value="model"/>
  </forward>
  <view>
    <forward servlet ="XSLTServlet">
      <set-attribute name="xslt.stylesheet" value = "display.xsl"/>
      <set-attribute name="xslt.input" value="model"/>
    </forward>

  <cache-control cache="no"/>
  </view>
</dispatch>    
else
(:   <ignore xmlns="http://exist.sourceforge.net/NS/exist"/>  :)
<dispatch xmlns="http://exist.sourceforge.net/NS/exist">
  <cache-control cache="no"/>
</dispatch>
