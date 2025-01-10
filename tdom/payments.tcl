
package require tdom

namespace eval ps {

    # Тип даних "billsRegistry". Структура Реєстру електронних платіжних рахунків
    namespace eval billRegistry {
        dom createNodeCmd -jsonType OBJECT elementNode billRegistry
        dom createNodeCmd -jsonType NONE elementNode header
        dom createNodeCmd -jsonType ARRAY elementNode bills

        # Тип даних "billsRegistryHeader". Структура заголовку Реєстру електронних платіжних рахунків
        namespace eval billRegistryHeader {
            dom createNodeCmd -jsonType OBJECT elementNode billRegistryHeader
            dom createNodeCmd -jsonType NONE elementNode edrpoy
            dom createNodeCmd -jsonType NONE elementNode name
            dom createNodeCmd -jsonType NONE elementNode iban
            dom createNodeCmd -jsonType NONE elementNode serviceCode
            dom createNodeCmd -jsonType NONE elementNode serviceName
            dom createNodeCmd -jsonType NONE elementNode period
        }
    
        # Тип даних "bill". Структура запису Реєстру електронних платіжних рахунків
        namespace eval bill {
            dom createNodeCmd -jsonType OBJECT elementNode bill
            dom createNodeCmd -jsonType NONE elementNode fullName
            dom createNodeCmd -jsonType NONE elementNode region
            dom createNodeCmd -jsonType NONE elementNode district
            dom createNodeCmd -jsonType NONE elementNode fullAddress
            dom createNodeCmd -jsonType NONE elementNode city
            dom createNodeCmd -jsonType NONE elementNode street
            dom createNodeCmd -jsonType NONE elementNode house
            dom createNodeCmd -jsonType NONE elementNode building
            dom createNodeCmd -jsonType NONE elementNode apartment
            dom createNodeCmd -jsonType NONE elementNode account
            dom createNodeCmd -jsonType NONE elementNode monthDebt
            dom createNodeCmd -jsonType NONE elementNode fullDebt
            dom createNodeCmd -jsonType ARRAY elementNode meters
    
            # Тип даних "meter". Структура для представлення зустрічних відомостей
            namespace eval meter {
                dom createNodeCmd -jsonType OBJECT elementNode meter
                dom createNodeCmd -jsonType NONE elementNode number
                dom createNodeCmd -jsonType NONE elementNode zoneQuantity
                dom createNodeCmd -jsonType NONE elementNode tariff1
                dom createNodeCmd -jsonType NONE elementNode previousReading1
                dom createNodeCmd -jsonType NONE elementNode currentReading1
                dom createNodeCmd -jsonType NONE elementNode tariff2
                dom createNodeCmd -jsonType NONE elementNode previousReading2
                dom createNodeCmd -jsonType NONE elementNode currentReading2
                dom createNodeCmd -jsonType NONE elementNode tariff3
                dom createNodeCmd -jsonType NONE elementNode previousReading3
                dom createNodeCmd -jsonType NONE elementNode currentReading3
            }
        }
    }

    dom createNodeCmd -jsonType ARRAY  elementNode array
    dom createNodeCmd -jsonType NUMBER textNode number
    dom createNodeCmd -jsonType STRING textNode string
    dom createNodeCmd -jsonType TRUE   textNode true
    dom createNodeCmd -jsonType FALSE  textNode false
    dom createNodeCmd -jsonType NULL   textNode null
}

set json [dom createDocumentNode]

namespace eval ps {
    $json appendFromScript {
        namespace eval billRegistry {
            billRegistry {
                namespace eval billRegistryHeader {
                    billRegistryHeader {
                        edrpoy      {ps::string ""}
                        name        {ps::string ""}
                        iban        {ps::string ""}
                        serviceCode {ps::string ""}
                        serviceName {ps::string ""}
                        period      {ps::string ""}
                    }
                }
                bills {
                    namespace eval bill {
                        bill {
                            fullName      {ps::string ""}
                            region        {ps::string ""}
                            district      {ps::string ""}
                            fullAddress   {ps::string ""}
                            city          {ps::string ""}
                            street        {ps::string ""}
                            house         {ps::string ""}
                            building      {ps::string ""}
                            apartment     {ps::string ""}
                            account       {ps::string ""}
                            monthDebt     {ps::number 0}
                            fullDebt      {ps::number 0}
                            meters {
                                namespace eval meter {
                                    meter {
                                        number           {ps::string "M1"}
                                        zoneQuantity     {ps::number 1}
                                        tariff1          {ps::number 1.11}
                                        previousReading1 {ps::number 1}
                                        currentReading1  {ps::number 11}
                                    }
                                    meter {
                                        number           {ps::string "M2"}
                                        zoneQuantity     {ps::number 2}
                                        tariff1          {ps::number 12.22}
                                        previousReading1 {ps::number 12}
                                        currentReading1  {ps::number 122}
                                        tariff2          {ps::number 22.22}
                                        previousReading2 {ps::number 22}
                                        currentReading2  {ps::number 222}
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

puts [$json asXML -indent 4]
puts [$json asJSON -indent 4]
