package require tdom 0.9.5-

proc json2dict {json} {
    set doc [dom parse -json $json]
    set dict [$doc asTclValue]
    $doc delete
    return $dict
}

set json {{"header":{"edrpoy":"999999999","name":"���� �� ������","iban":"UA708999980000000000000099999","serviceCode":"1","serviceName":"ĳ��� �� �������","period":"2024-01"},"bills":[{"fullName":"������ ���� ��������","region":"���������������","district":"����������������","fullAddress":"","city":"�����","street":"�������� ��������","house":"1","building":"","apartment":"1","account":"123456789","monthDebt":"12","fullDebt":"123.45","meterCount":"0","meters":[]},{"fullName":"������ ���� ��������","region":"���������������","district":"����������������","fullAddress":"","city":"�����","street":"�������� ��������","house":"2","building":"","apartment":"2","account":"234567890","monthDebt":"12","fullDebt":"123.45","meterCount":"1","meters":[{"number":"","zoneQuantity":"1","tariff1":"","previousReading1":"0","currentReading1":"0"}]}]}}

puts [json2dict $json]
