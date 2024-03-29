Mad.StringStream = function(string) {
    this.state = { offset: 0, buffer: string, amountRead: string.length, length: string.length };
}

Mad.StringStream.prototype = new Mad.ByteStream();

Mad.StringStream.prototype.absoluteAvailable = function(n, updated) {
    return n < this.state['amountRead'];
}

Mad.StringStream.prototype.seek = function(n) {
    this.state['offset'] += n;
}

Mad.StringStream.prototype.read = function(n) {
    var result = this.peek(n);
    
    this.seek(n);
    
    return result;
}

Mad.StringStream.prototype.peek = function(n) {
    if (this.available(n)) {
        var offset = this.state['offset'];
        
        var result = this.get(offset, n);
        
        return result;
    } else {
        throw new Error('Buffer underflow with peek!');
    }
}

Mad.StringStream.prototype.get = function(offset, length) {
    if (this.absoluteAvailable(offset + length)) {
        return this.state['buffer'].slice(offset, offset + length);
    } else {
        console.log('Need to buffer');
		return '';
    }
}

Mad.StringStream.prototype.buffer = function(data) {
	var newBuffer = this.state['buffer'] + data
	this.state['buffer'] = newBuffer;
	this.state['amountRead'] = newBuffer.length;
	this.state['length'] = newBuffer.length;	
}