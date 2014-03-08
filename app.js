$(function(){
	
	var top_level_nodes = [];
	
	var doc_name = location.search || "document";
	load();
	
	function load(){
		function load_node(node){
			$Node(node).html(node._);
		}
		load_doc(doc_name, function(doc){
			if(doc){
				$.each(doc.nodes, load_node);
			}else{
				$Node({
					x: innerWidth / 2,
					y: innerHeight / 3,
				}).focus();
			}
		});
	}
	function save(){
		function serialize($node){
			var node = {
				x: $node.x,
				y: $node.y,
				_: $node.html()
			};
			if($node.$children){
				node.c = $.map($node.$children, serialize);
			}
			return node;
		}
		//serialize the document
		documents[doc_name] = 
		documents[doc_name] || {};
		documents[doc_name].nodes = $.map(top_level_nodes, serialize);
		//save
		save_doc(doc_name);
	}
	
	$("body").on("mousedown", function(e){
		var $n = $Node({
			x: e.clientX,
			y: e.clientY,
		}).focus();
		
		setTimeout(function(e){
			$n.focus();
		});
	});
	
	var $empty;
	function $Node(o){
		$empty && $empty.remove();
		
		var $n = $empty = $("<div contenteditable class='n'></div>")
		.appendTo("body")
		.css({
			position: "absolute",
			padding: "5px",
			outline: "none",
			fontSize: "2em"
		})
		.on("keydown", function(e){
			if($n.html().match(/^\s*$/)){
				$empty = $n;
			}else{
				$empty = null;
			}
			if(e.keyCode === 13 && !e.shiftKey){
				e.preventDefault();
				$Node({
					x: o.x + Math.random()*100-50,
					y: o.y + 50,
				}).focus();
			}
			save(doc_name);
		})
		.on("keydown keyup keypress", function(){
			center();
			setTimeout(center);
		})
		.on("mousedown", function(e){
			e.stopPropagation();
		});
		
		center(true);
		
		top_level_nodes.push($n);
		
		return $n;
		
		function center(instantly){
			if(instantly){
				$n.css({
					left: o.x - $n.outerWidth()/2,
					top: o.y - $n.outerHeight()/2,
				});
			}else{
				$n.css({
					animation: "left .2s ease-in-out, top .2s ease-in-out",
					"-webkit-animation": "left 2s ease-in-out, top 2s ease-in-out",
					left: o.x - $n.outerWidth()/2,
					top: o.y - $n.outerHeight()/2,
				});
			}
		}
	}
	
});