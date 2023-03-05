. $PSSCriptRoot\DnSimplePS.ps1

function WriteTheToken($account,$token,$p) {
    Write-AccessToken -Account $account -AccessToken $token -Path $p
}

Describe 'DnSimplePS module' {
    Context 'Token storage' {
        It 'Should write access tokens to file' {
            $p = join-path $TestDrive '.storage'
            WriteTheToken 'a' 'x' $p
            [xml](Get-Content $p) | Select-Xml "/s:Objs/s:Obj/s:DCT/s:En/s:S[text()='a']" `
                -ErrorAction 'silentlycontinue' `
                -Namespace @{s = 'http://schemas.microsoft.com/powershell/2004/04'} `
                | Should Not BeNullOrEmpty
        }

        It 'Should be able to read access tokens from file' {
            $p = join-path $TestDrive '.storage'
            WriteTheToken 'a' 'x' $p
            $result = Read-AccessToken 'a' $p
            $result.AccessToken | Should BeOfType System.Security.SecureString
            $result.Account | Should Be 'a'
        }
    }

    Context 'Zone retrieval and updates' {
        Mock Invoke-RestMethod {
            return [PSCustomObject]@{
                data = [PSCustomObject]@{
                    id=11278049
                    zone_id='kongs.li'
                    parent_id=$null
                    name='posh'
                    content='https://www.kongsli.net/category/microsoft-technologies/powershell/'
                    ttl=3600
                    priority=$null
                    type='URL'
                    regions=@('global')
                    system_record=$false
                    created_at='2017-03-24T11:53:27Z'
                    updated_at='2017-03-24T11:53:27Z'
                }
            }

        } -ParameterFilter { $Method -eq 'Get' -and $Id -eq 11278049 }

        It 'should be able to retrieve zone record by id' {
            $acc = [pscustomobject]@{
                Account = 1
                AccessToken = (ConvertTo-SecureString -AsPlainText 'foo' -Force) 
            }
            $result = $acc | Get-ZoneRecord -Zone 'kongs.li' -Id 11278049
            $result.name | Should Be 'posh' 

            Assert-MockCalled Invoke-RestMethod -Times 1 -Scope It
        }

        Mock Invoke-RestMethod {
            return [PSCustomObject]@{
                data = @(
                    [PSCustomObject]@{
                        id=6717354
                        zone_id='kongs.li'
                        parent_id=$null
                        name=$null
                        content='mxa.mailgun.org'
                        ttl=3600
                        priority=10
                        type='MX'
                        regions=@('global')
                        system_record=$false
                        created_at='2017-03-24T11:53:27Z'
                        updated_at='2017-03-24T11:53:27Z'
                    },
                    [PSCustomObject]@{
                        id=6717355
                        zone_id='kongs.li'
                        parent_id=$null
                        name=$null
                        content='mxb.mailgun.org'
                        ttl=3600
                        priority=10
                        type='MX'
                        regions=@('global')
                        system_record=$false
                        created_at='2017-03-24T11:53:27Z'
                        updated_at='2017-03-24T11:53:27Z'
                    }
                )
            }

        } -ParameterFilter { $Method -eq 'Get' -and $RecordType -eq 'MX' }

        It 'should be able to retrieve zones record by record type' {
            $acc = [pscustomobject]@{
                Account = 1
                AccessToken = (ConvertTo-SecureString -AsPlainText 'foo' -Force) 
            }
            $result = $acc | Get-ZoneRecord -Zone 'kongs.li' -RecordType MX -Search
            $result.Count | Should Be 2 

            Assert-MockCalled Invoke-RestMethod -Times 1 -Scope It
        }

        Mock Invoke-RestMethod {
            $bodyPS = ConvertFrom-Json $Body
            return [PSCustomObject]@{
                data = [PSCustomObject]@{
                    id=11278049
                    zone_id=$Zone
                    parent_id=$null
                    name=$bodyPS.name
                    content=$bodyPS.Content
                    ttl=3600
                    priority=$null
                    type=$bodyPS.type
                    regions=@('global')
                    system_record=$false
                    created_at='2017-03-24T11:53:27Z'
                    updated_at='2017-03-24T11:53:27Z'
                }
            }
        } -ParameterFilter { $Method -eq 'POST' -and $Uri -eq 'https://api.dnsimple.com/v2/1/zones/somesite.com/records' }

        It 'should be able to add zone record' {
            $acc = [pscustomobject]@{
                Account = 1
                AccessToken = (ConvertTo-SecureString -AsPlainText 'foo' -Force) 
            }
            $zone = 'somesite.com'
            $content = 'http://somewhere.else.com'
            $recordName = 'test1'
            $result = $acc | Add-ZoneRecord -Zone $zone -Name $recordName -RecordType URL `
                -Content $content

            $result.zone_id | Should be $zone
            $result.content | Should be $content
            $result.name | Should be $recordName

            Assert-MockCalled Invoke-RestMethod -Times 1 -Scope It
        } 

        Mock Invoke-WebRequest {
            return [pscustomobject]@{
                StatusCode=204
                StatusDescription='No Content'
                Content=''
                RawContentLength=0
            }
        } -ParameterFilter { $Method -eq 'DELETE' -and $Uri -eq 'https://api.dnsimple.com/v2/1/zones/somesite.com/records/1' } 

        It 'should be able to delete record' {
            $acc = [pscustomobject]@{
                Account = 1
                AccessToken = (ConvertTo-SecureString -AsPlainText 'foo' -Force) 
            }
            $zone = 'somesite.com'
            $result = $acc | Remove-ZoneRecord -Zone $zone -Id 1
            $result.StatusCode | Should Be 204

            Assert-MockCalled Invoke-WebRequest -Times 1 -Scope It
         }
    }
}
