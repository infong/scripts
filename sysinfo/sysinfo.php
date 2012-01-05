<?php

/**
 * PHP sysinfo
 * 
 * PHP version 5
 *
 * @author Infong <clarelyf@gmail.com>
 * @date    2012/01/01
 *
 */


@header("content-Type: text/html; charset=utf-8");
error_reporting(0);
define('USE_VHOST', FALSE);

$time_start = CommonFunctions::microTimeFloat();

/**
 * CommonFunctions class
 */ 
class CommonFunctions
{
    static function microTimeFloat()
    {
        $mtime = microtime();
        $mtime = explode(' ', $mtime);
        return $mtime[1] + $mtime[0];
    }

    static function memoryUsage()
    {
        $memory = (!function_exists('memory_get_usage')) ? '0' : round(memory_get_usage() / 1024 / 1024, 2) . 'MB';
        return $memory;
    }

    static function calPercent($divis, $divid)
    {
        if($divid > 0) {
            return ceil($divis / $divid * 100);
        } else {
            return 0;
        }
    }

    private static function _findProgram($strProgram)
    {
        $path = getenv("Path") ? getenv("Path") : "/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:/opt/bin:/opt/sbin";
        $arrPath = array();
        if (PHP_OS == 'WINNT') {
            $strProgram .= '.exe';
            $arrPath = preg_split('/;/', $path, -1, PREG_SPLIT_NO_EMPTY);
        } else {
            $arrPath = preg_split('/:/', $path, -1, PREG_SPLIT_NO_EMPTY);
        }
        
        if ((bool)ini_get('open_basedir')) {
            $open_basedir = preg_split('/:/', ini_get('open_basedir'), -1, PREG_SPLIT_NO_EMPTY);
        }
        foreach ($arrPath as $strPath) {
            if ((isset($open_basedir) && !in_array($strPath, $open_basedir)) || !is_dir($strPath)) {
                continue;
            }
            $strProgrammpath = $strPath."/".$strProgram;
            if (is_executable($strProgrammpath)) {
                return $strProgrammpath;
            }
        }
        return FALSE;
    }

    static function executeProgram($commandName, $args, &$result)
    {
        $buffer = "";
        if (FALSE === ($command = self::_findProgram($commandName))) return FALSE;
        if ($fp = @popen("$command $args", 'r')) {
            while (!@feof($fp)) {
                $buffer .= @fgets($fp, 4096);
            }
            $result = trim($buffer);
            return TRUE;
        }
        return FALSE;
    }

    public static function df($df_param = "")
    {
        $arrResult = array();
        if (CommonFunctions::executeProgram('df', '-k '.$df_param, $df)) {
            $df = preg_split("/\n/", $df, -1, PREG_SPLIT_NO_EMPTY);
            if (CommonFunctions::executeProgram('mount', '', $mount)) {
                $mount = preg_split("/\n/", $mount, -1, PREG_SPLIT_NO_EMPTY);
                foreach ($mount as $mount_line) {
                    if (preg_match("/\S+ on (\S+) type (.*) \((.*)\)/", $mount_line, $mount_buf)) {
                        $mount_parm[$mount_buf[1]]['fstype'] = $mount_buf[2];
                        $mount_parm[$mount_buf[1]]['options'] = $mount_buf[3];
                    } elseif (preg_match("/\S+ (.*) on (\S+) \((.*)\)/", $mount_line, $mount_buf)) {
                        $mount_parm[$mount_buf[2]]['fstype'] = $mount_buf[1];
                        $mount_parm[$mount_buf[2]]['options'] = $mount_buf[3];
                    } elseif (preg_match("/\S+ on ([\S ]+) \((\S+)(,\s(.*))?\)/", $mount_line, $mount_buf)) {
                        $mount_parm[$mount_buf[1]]['fstype'] = $mount_buf[2];
                        $mount_parm[$mount_buf[1]]['options'] = isset($mount_buf[4]) ? $mount_buf[4] : '';
                    }
                }
                foreach ($df as $df_line) {
                    $df_buf1 = preg_split("/(\%\s)/", $df_line, 2);
                    if (count($df_buf1) != 2) {
                        continue;
                    }
                    if (preg_match("/(.*)(\s+)(([0-9]+)(\s+)([0-9]+)(\s+)([0-9]+)(\s+)([0-9]+)$)/", $df_buf1[0], $df_buf2)) {
                        $df_buf = array($df_buf2[1], $df_buf2[4], $df_buf2[6], $df_buf2[8], $df_buf2[10], $df_buf1[1]);
                        if (count($df_buf) == 6) {
                            $df_buf[5] = trim($df_buf[5]);
                            $dev = array();
                            $dev['name'] = trim($df_buf[0]);
                            if ($df_buf[2] < 0) {
                                $dev['total'] = $df_buf[3] * 1024;
                                $dev['used']  = $df_buf[3] * 1024;
                                $dev['free']  = 0;
                            } else {
                                $dev['total'] = $df_buf[1] * 1024;
                                $dev['used']  = $df_buf[2] * 1024;
                                $dev['free']  = $df_buf[3] * 1024;
                            }
                            $dev['mountpoint'] = $df_buf[5];

                            if(isset($mount_parm[$df_buf[5]])) {
                                $dev['fstype'] = $mount_parm[$df_buf[5]]['fstype'];
                                $dev['options'] = $mount_parm[$df_buf[5]]['options'];
                            }
                            $arrResult[] = $dev;
                        }
                    }
                }
            }
        }
        return $arrResult;
    }

    public static function rfts($strFileName, &$strRet, $intLines = 0, $intBytes = 4096)
    {
        $strFile = "";
        $intCurLine = 1;
        if (file_exists($strFileName)) {
            if ($fd = fopen($strFileName, 'r')) {
                while (!feof($fd)) {
                    $strFile .= fgets($fd, $intBytes);
                    if ($intLines <= $intCurLine && $intLines != 0) {
                        break;
                    } else {
                        $intCurLine++;
                    }
                }
                fclose($fd);
                $strRet = $strFile;
            } else {
                return false;
            }
        } else {
            return false;
        }
        return true;
    }
    
    public static function formatsize($size,$s=FALSE) 
    {
        $danwei=array(' B ',' K ',' M ',' G ',' T ');
        $allsize=array();
        $i=0;
        for($i = 0; $i < 4; $i++) {
            if(floor($size/pow(1024,$i))==0){
                break;
            }
        }
        $allsize1 = array();
        $allsize1[$i] = floor($size/pow(1024,$i));
        if($i == 0) return 0;
        if($s) {
            $sfsize = round($size/pow(1024,$i-1), 2);
            return $sfsize.$danwei[$i-1];
        }
        for($l = $i-1; $l >= 0; $l--) {
            $allsize1[$l] = floor($size/pow(1024,$l));
            $allsize[$l] = $allsize1[$l]-$allsize1[$l+1]*1024;
            $allsize[$l] .= $danwei[$l];
        }
        $fsize = implode('', $allsize);
        return $fsize;
    }
    
    public static function formatUptime($seconds)
    {
        $min = $seconds / 60;
        $hours = $min / 60;
        $res['uptimes'] = round($hours/24, 2);
        $days = floor($hours / 24);
        $hours = floor($hours - ($days * 24));
        $min = floor($min - ($days * 60 * 24) - ($hours * 60));
        $uptime = '';
        if ($days != 0) $uptime = $days." day(s) ";
        if ($hours != 0) {
            $uptime .= $hours . ":" . $min;
        } else {
            $uptime .= $min . " min";
        }
        return $uptime;
    }
    
}

class System 
{
    private $_ostype = 'Unknown';
    private $_hostname = 'localhost';
    private $_ip = '127.0.0.1';
    private $_kernel = 'Unknown';
    private $_cpuCores = 0;
    private $_cpusInfo = array();
    private $_time = '';
    private $_uptime = 0;
    private $_loadAverage = '';
    private $_filesystems = array();
    private $_memoryTotal = 0;
    private $_memoryUsed = 0;
    private $_memoryFree = 0;
    private $_memoryBuffer = 0;
    private $_memoryCache = 0;
    private $_swapTotal = 0;
    private $_swapUsed = 0;
    private $_networkInfo = array();

    public function setTime()
    {
        $this->_time = time();
    }

    public function getTime($format = 'Y-m-d H:i:s')
    {
        return date($format, $this->_time);
    }

    public function setOSType()
    {
        $this->_ostype = PHP_OS;
    }

    public function getOSType()
    {
        return $this->_ostype;
    }

    public function setUptime($uptime)
    {
        $this->_uptime = $uptime;
    }

    public function getUptime()
    {
        return $this->_uptime;
    }

    public function setCpusInfo($cpuInfo)
    {
        array_push($this->_cpusInfo, $cpuInfo);
    }
    
    public function getCpusInfo()
    {
        return $this->_cpusInfo;
    }
    
    public function getCpusNumber()
    {
        return count($this->_cpusInfo);
    }

    public function getHostname()
    {
        return $this->_hostname;
    }

    public function setHostname($hostname)
    {
        $this->_hostname = $hostname;
    }

    public function getIp()
    {
        return $this->_ip;
    }

    public function setIp($ip)
    {
        $this->_ip = $ip;
    }

    public function getKernel()
    {
        return $this->_kernel;
    }

    public function setKernel($kernel)
    {
        $this->_kernel = $kernel;
    }

    public function getLoad()
    {
        return $this->_loadAverage;
    }

    public function setLoad($loadAverage)
    {
        $this->_loadAverage = $loadAverage;
    }

    public function setFilesystems($filesystem)
    {
        $this->_filesystems[] = $filesystem;
    }

    public function getFilesystems()
    {
        return $this->_filesystems;
    }

    public function setMemTotal($memoryTotal)
    {
        $this->_memoryTotal = $memoryTotal;
    }

    public function getMemTotal()
    {
        return $this->_memoryTotal;
    }

    public function setMemFree($memoryFree)
    {
        $this->_memoryFree = $memoryFree;
    }

    public function getMemFree()
    {
        return $this->_memoryFree;
    }

    public function setMemUsed($memoryUsed)
    {
        $this->_memoryUsed = $memoryUsed;
    }

    public function getMemUsed()
    {
        return $this->_memoryUsed;
    }

    public function getMemRealUsed()
    {
        return $this->_memoryUsed - $this->_memoryBuffer - $this->_memoryCache;
    }

    public function setMemBuffer($memBuffer)
    {
        $this->_memoryBuffer = $memBuffer;
    }

    public function getMemBuffer()
    {
        return $this->_memoryBuffer;
    }

    public function getMemCache()
    {
        return $this->_memoryCache;
    }

    public function setMemCache($memCache)
    {
        $this->_memoryCache = $memCache;
    }

    public function getMemPercentUsed()
    {
        if ($this->_memoryTotal > 0) {
            return ceil($this->_memoryUsed / $this->_memoryTotal * 100);
        } else {
            return 0;
        }
    }

    public function getMemPercentRealUsed()
    {
        if ($this->_memoryTotal > 0) {
            return ceil($this->getMemRealUsed() / $this->_memoryTotal * 100);
        } else {
            return 0;
        }
    }

    public function getMemPercentBuffer()
    {
        if ($this->_memoryTotal > 0) {
            return ceil($this->_memoryBuffer / $this->_memoryTotal * 100);
        } else {
            return 0;
        }
    }

    public function getMemPercentCache()
    {
        if ($this->_memoryTotal > 0) {
            return ceil($this->_memoryCache / $this->_memoryTotal * 100);
        } else {
            return 0;
        }
    }

    public function setSwapUsed($swapUsedSize)
    {
        $this->_swapUsed += $swapUsedSize;
    }

    public function getSwapPercentUsed()
    {
        if ($this->_swapTotal > 0) {
            return ceil($this->_swapUsed / $this->_swapTotal * 100);
        } else {
            return 0;
        }
    }

    public function getSwapUsed()
    {
        return $this->_swapUsed;
    }

    public function setSwapTotal($swapSize)
    {
        $this->_swapTotal += $swapSize;
    }

    public function getSwapTotal(){
        return $this->_swapTotal;
    }

    public function getNetworkInfo()
    {
        return $this->_networkInfo;
    }

    public function setNetworkInfo($networkInfo)
    {
        array_push($this->_networkInfo,$networkInfo);
    }
}

abstract class OS
{

    protected $sys;
    protected $si;

    function __construct()
    {
        $this->sys = new System();
        $this->build();
        $this->sys->setOSType();
        $this->sys->setTime();
        $this->si = new ServerInfo();
    }
    
    public final function getSys()
    {
        return $this->sys;
    }
    
    public final function getServerInfo()
    {
        return $this->si;
    }
}

 /**
 * Linux sysinfo class
 * get all the required information from Linux system
 */

class LinuxOS extends OS
{

    function __construct()
    {
        parent::__construct();
    }
    
    private function _hostname()
    {
        if (USE_VHOST === true) {
            $this->sys->setHostname(getenv('SERVER_NAME'));
        } else {
            if (CommonFunctions::rfts('/proc/sys/kernel/hostname', $result, 1)) {
                $result = trim($result);
                $ip = gethostbyname($result);
                if ($ip != $result) {
                    $this->sys->setHostname(gethostbyaddr($ip));
                }
            }
        }
    }
    
    private function _ip()
    {
        if (USE_VHOST === true) {
            $this->sys->setIp(gethostbyname($this->_hostname()));
        } else {
            if (!($result = $_SERVER['SERVER_ADDR'])) {
                $this->sys->setIp(gethostbyname($this->_hostname()));
            } else {
                $this->sys->setIp($result);
            }
        }
    }
    
    private function _kernel()
    {
        if (CommonFunctions::executeProgram('uname', '-r', $strBuf)) {
            $result = trim($strBuf);
            if (CommonFunctions::executeProgram('uname', '-v', $strBuf)) {
                if (preg_match('/SMP/', $strBuf)) {
                    $result .= ' (SMP)';
                }
            }
            if (CommonFunctions::executeProgram('uname', '-m', $strBuf)) {
                $result .= ' '.trim($strBuf);
            }
            $this->sys->setKernel($result);
        } else {
            if (CommonFunctions::rfts('/proc/version', $strBuf, 1)) {
                if (preg_match('/version (.*?) /', $strBuf, $ar_buf)) {
                    $result = $ar_buf[1];
                    if (preg_match('/SMP/', $strBuf)) {
                        $result .= ' (SMP)';
                    }
                    $this->sys->setKernel($result);
                }
            }
        }
    }
    
    private function _uptime()
    {
        CommonFunctions::rfts('/proc/uptime', $buf, 1);
        $ar_buf = preg_split('/ /', $buf);
        $this->sys->setUptime(trim($ar_buf[0]));
    }
    

    private function _loadavg()
    {
        if (CommonFunctions::rfts('/proc/loadavg', $buf)) {
            $result = preg_split("/\s/", $buf, 4);
            // don't need the extra values, only first three
            unset($result[3]);
            $this->sys->setLoad(implode(' ', $result));
        }
    }
    
    private function _cpuinfo()
    {
        if (CommonFunctions::rfts('/proc/cpuinfo', $bufr)) {
            preg_match_all("/model\s+name\s{0,}\:+\s{0,}([\w\s\)\(\@.-]+)([\r\n]+)/s", $bufr, $model);
            preg_match_all("/cpu\s+MHz\s{0,}\:+\s{0,}([\d\.]+)[\r\n]+/", $bufr, $mhz);
            preg_match_all("/cache\s+size\s{0,}\:+\s{0,}([\d\.]+\s{0,}[A-Z]+[\r\n]+)/", $bufr, $cache);
            preg_match_all("/bogomips\s{0,}\:+\s{0,}([\d\.]+)[\r\n]+/", $bufr, $bogomips);

            if (is_array($model[1])) {
                $number = count($model[1]);
                for($i = 0; $i < $number; $i++){
                    $cpuinfo = array(
                        'model'    => trim($model[1][$i]),
                        'mhz'      => trim($mhz[1][$i]),
                        'cache'    => trim($cache[1][$i]),
                        'bogomips' => trim($bogomips[1][$i]),
                    );
                    $this->sys->setCpusInfo($cpuinfo);
                }
            }
            
        }
    }
    
    private function _network()
    {
        if (CommonFunctions::rfts('/proc/net/dev', $bufr)) {
            $bufe = preg_split("/\n/", $bufr, -1, PREG_SPLIT_NO_EMPTY);
            foreach ($bufe as $buf) {
                if (preg_match('/:/', $buf)) {
                    list($dev_name, $stats_list) = preg_split('/:/', $buf, 2);
                    $stats = preg_split('/\s+/', trim($stats_list));
                    $networkInfo = array(
                        'dev' => trim($dev_name),
                        'rx'  => $stats[0],
                        'tx'  => $stats[8],
                    );
                    $this->sys->setNetworkInfo($networkInfo);
                }
            }
        }
    }

    private function _disk()
    {
        $arrResult = CommonFunctions::df("-P");
        foreach ($arrResult as $dev) {
            $this->sys->setFilesystems($dev);
        }
    }

    private function _memory()
    {
        if (CommonFunctions::rfts('/proc/meminfo', $bufr)) {
            $bufe = preg_split("/\n/", $bufr, -1, PREG_SPLIT_NO_EMPTY);
            foreach ($bufe as $buf) {
                if (preg_match('/^MemTotal:\s+(.*)\s*kB/i', $buf, $ar_buf)) {
                    $this->sys->setMemTotal($ar_buf[1] * 1024);
                } elseif (preg_match('/^MemFree:\s+(.*)\s*kB/i', $buf, $ar_buf)) {
                    $this->sys->setMemFree($ar_buf[1] * 1024);
                } elseif (preg_match('/^Cached:\s+(.*)\s*kB/i', $buf, $ar_buf)) {
                    $this->sys->setMemCache($ar_buf[1] * 1024);
                } elseif (preg_match('/^Buffers:\s+(.*)\s*kB/i', $buf, $ar_buf)) {
                    $this->sys->setMemBuffer($ar_buf[1] * 1024);
                }
            }
            $this->sys->setMemUsed($this->sys->getMemTotal() - $this->sys->getMemFree());
            if (CommonFunctions::rfts('/proc/swaps', $bufr)) {
                $swaps = preg_split("/\n/", $bufr, -1, PREG_SPLIT_NO_EMPTY);
                unset($swaps[0]);
                foreach ($swaps as $swap) {
                    $ar_buf = preg_split('/\s+/', $swap, 5);
                    $this->sys->setSwapTotal($ar_buf[2] * 1024);
                    $this->sys->setSwapUsed($ar_buf[3] * 1024);
                }
            }
        }
    }
    
    public function build()
    {
        $this->_hostname();
        $this->_ip();
        $this->_kernel();
        $this->_uptime();
        $this->_loadavg();
        $this->_cpuinfo();
        $this->_network();
        $this->_disk();
        $this->_memory();
    }
}

 /**
 * WINNT sysinfo class
 * get all the required information from WINNT systems
 * information are retrieved through the WMI interface
 */

class WinNT extends OS
{
    function __construct()
    {
        parent::__construct();

        $strHostname = '';
        $strUser = '';
        $strPassword = '';
        $objLocator = new COM('WbemScripting.SWbemLocator');
        if ($strHostname == "") {
            $this->_wmi = $objLocator->ConnectServer();
        } else {
            $this->_wmi = $objLocator->ConnectServer($strHostname, 'rootcimv2', $strHostname.'\\'.$strUser, $strPassword);
        }
        $this->_getCodeSet();
    }

    private function _getCodeSet()
    {
        $buffer = $this->_getWMI('Win32_OperatingSystem', array('CodeSet'));
        $this->_charset = 'windows-'.$buffer[0]['CodeSet'];
    }
    
    private function _getWMI($strClass, $strValue = array())
    {
        $arrData = array();
        $value = "";
        try {
            $objWEBM = $this->_wmi->Get($strClass);
            $arrProp = $objWEBM->Properties_;
            $arrWEBMCol = $objWEBM->Instances_();
            foreach ($arrWEBMCol as $objItem) {
                if (is_array($arrProp)) {
                    reset($arrProp);
                }
                $arrInstance = array();
                foreach ($arrProp as $propItem) {
                    eval("\$value = \$objItem->".$propItem->Name.";");
                    if ( empty($strValue)) {
                        $arrInstance[$propItem->Name] = trim($value);
                    } else {
                        if (in_array($propItem->Name, $strValue)) {
                            $arrInstance[$propItem->Name] = trim($value);
                        }
                    }
                }
                $arrData[] = $arrInstance;
            }
        }
        catch(Exception $e) {
            echo $e->getCode() . $e->getMessage();
        }
        return $arrData;
    }

    private function _ip()
    {
        if (USE_VHOST === true) {
            $this->sys->setIp(gethostbyname($this->_hostname()));
        } else {
            $buffer = $this->_getWMI('Win32_ComputerSystem', array('Name'));
            $result = $buffer[0]['Name'];
            $this->sys->setIp(gethostbyname($result));
        }
    }

    private function _hostname()
    {
        if (USE_VHOST === true) {
            $this->sys->setHostname(getenv('SERVER_NAME'));
        } else {
            $buffer = $this->_getWMI('Win32_ComputerSystem', array('Name'));
            $result = $buffer[0]['Name'];
            $ip = gethostbyname($result);
            if ($ip != $result) {
                $this->sys->setHostname(gethostbyaddr($ip));
            }
        }
    }

    private function _uptime()
    {
        $result = 0;
        date_default_timezone_set('UTC');
        $buffer = $this->_getWMI('Win32_OperatingSystem', array('LastBootUpTime', 'LocalDateTime'));
        $byear = intval(substr($buffer[0]['LastBootUpTime'], 0, 4));
        $bmonth = intval(substr($buffer[0]['LastBootUpTime'], 4, 2));
        $bday = intval(substr($buffer[0]['LastBootUpTime'], 6, 2));
        $bhour = intval(substr($buffer[0]['LastBootUpTime'], 8, 2));
        $bminute = intval(substr($buffer[0]['LastBootUpTime'], 10, 2));
        $bseconds = intval(substr($buffer[0]['LastBootUpTime'], 12, 2));
        $lyear = intval(substr($buffer[0]['LocalDateTime'], 0, 4));
        $lmonth = intval(substr($buffer[0]['LocalDateTime'], 4, 2));
        $lday = intval(substr($buffer[0]['LocalDateTime'], 6, 2));
        $lhour = intval(substr($buffer[0]['LocalDateTime'], 8, 2));
        $lminute = intval(substr($buffer[0]['LocalDateTime'], 10, 2));
        $lseconds = intval(substr($buffer[0]['LocalDateTime'], 12, 2));
        $boottime = mktime($bhour, $bminute, $bseconds, $bmonth, $bday, $byear);
        $localtime = mktime($lhour, $lminute, $lseconds, $lmonth, $lday, $lyear);
        $result = $localtime - $boottime;
        $this->sys->setUptime($result);
    }

    private function _loadavg()
    {
        $loadavg = "";
        $sum = 0;
        $buffer = $this->_getWMI('Win32_Processor', array('LoadPercentage'));
        foreach ($buffer as $load) {
            $value = $load['LoadPercentage'];
            $loadavg .= $value.' ';
            $sum += $value;
        }
        $this->sys->setLoad(trim($loadavg));
    }

    private function _cpuinfo()
    {
        $allCpus = $this->_getWMI('Win32_Processor', array('Name', 'L2CacheSize', 'CurrentClockSpeed', 'ExtClock', 'NumberOfCores'));
        foreach ($allCpus as $oneCpu) {
            $coreCount = 1;
            if (isset($oneCpu['NumberOfCores'])) {
                $coreCount = $oneCpu['NumberOfCores'];
            }
            for ($i = 0; $i < $coreCount; $i++) {
                $cpuinfo = array(
                    'model'    => trim($oneCpu['Name']),
                    'mhz'      => trim($oneCpu['CurrentClockSpeed']),
                    'cache'    => trim($oneCpu['L2CacheSize'] * 1024),
                );
                $this->sys->setCpusInfo($cpuinfo);
            }
        }
    }

    private function _network()
    {
        foreach ($this->_getWMI('Win32_PerfRawData_Tcpip_NetworkInterface') as $device) {
            $networkInfo['dev'] = $device['Name'];

            $txbytes = $device['BytesSentPersec'];
            if ($txbytes < 0) {
                $txbytes = $device['BytesTotalPersec'] - $device['BytesReceivedPersec'];
            }
            $networkInfo['tx'] = $txbytes;
            $rxbytes = $device['BytesReceivedPersec'];
            if ($rxbytes < 0) {
                $rxbytes = $device['BytesTotalPersec'] - $device['BytesSentPersec'];
            }
            $networkInfo['rx'] = $rxbytes;
            $this->sys->setNetworkInfo($networkInfo);
        }
    }

    private function _memory()
    {
        $buffer = $this->_getWMI("Win32_OperatingSystem", array('TotalVisibleMemorySize', 'FreePhysicalMemory'));
        $this->sys->setMemTotal($buffer[0]['TotalVisibleMemorySize'] * 1024);
        $this->sys->setMemFree($buffer[0]['FreePhysicalMemory'] * 1024);
        $this->sys->setMemUsed($this->sys->getMemTotal() - $this->sys->getMemFree());
        
        $buffer = $this->_getWMI('Win32_PageFileUsage');
        foreach ($buffer as $swapdevice) {
            $this->sys->setSwapTotal($swapdevice['AllocatedBaseSize'] * 1024 * 1024);
            $this->sys->setSwapUsed($swapdevice['CurrentUsage'] * 1024 * 1024);
        }
    }

    private function _disk()
    {
        $typearray = array('Unknown', 'No Root Directory', 'Removable Disk', 'Local Disk', 'Network Drive', 'Compact Disc', 'RAM Disk');
        $floppyarray = array('Unknown', '5 1/4 in.', '3 1/2 in.', '3 1/2 in.', '3 1/2 in.', '3 1/2 in.', '5 1/4 in.', '5 1/4 in.', '5 1/4 in.', '5 1/4 in.', '5 1/4 in.', 'Other', 'HD', '3 1/2 in.', '3 1/2 in.', '5 1/4 in.', '5 1/4 in.', '3 1/2 in.', '3 1/2 in.', '5 1/4 in.', '3 1/2 in.', '3 1/2 in.', '8 in.');
        $buffer = $this->_getWMI('Win32_LogicalDisk', array('Name', 'Size', 'FreeSpace', 'FileSystem', 'DriveType', 'MediaType'));
        foreach ($buffer as $filesystem) {
            $dev = array();
            if ($filesystem['MediaType'] != "" && $filesystem['DriveType'] == 2) {
                $dev['name'] = $typearray[$filesystem['DriveType']]." (".$floppyarray[$filesystem['MediaType']].")";
            } else {
                $dev['name'] = $typearray[$filesystem['DriveType']];
            }
            $dev['total'] = $filesystem['Size'];
            $dev['free']  = $filesystem['FreeSpace'];
            $dev['used']  = $filesystem['Size'] - $filesystem['FreeSpace'];
            $dev['mountpoint'] = $filesystem['Name'];
            $dev['fstype'] = $filesystem['FileSystem'];
            $this->sys->setFilesystems($dev);
        }
    }

    function build()
    {
        $this->_ip();
        $this->_hostname();
        $this->_uptime();
        $this->_cpuinfo();
        $this->_network();
        $this->_memory();
        $this->_disk();
        $this->_loadavg();
    }
}

 /**
 * FreeBSD sysinfo class
 * get all the required information from FreeBSD system
 */

class FreeBSD extends OS
{

    private $_dmesg='';

    function __construct()
    {
        parent::__construct();
        $this->_CPURegExp1 = "CPU: (.*) \((.*)-MHz (.*)\)";
        $this->_CPURegExp2 = "/(.*) ([0-9]+) ([0-9]+) ([0-9]+) ([0-9]+)/";
    }

    private function _hostname()
    {
        if (USE_VHOST === true) {
            $this->sys->setHostname(getenv('SERVER_NAME'));
        } else {
            if (CommonFunctions::executeProgram('hostname', '', $buf)) {
                $this->sys->setHostname($buf);
            }
        }
    }

    public function grabkey($key)
    {
        $buf = "";
        if (CommonFunctions::executeProgram('sysctl', "-n $key", $buf)) {
            return $buf;
        } else {
            return '';
        }
    }

    public function readdmesg()
    {
        if (count($this->_dmesg) === 0) {
            if (CommonFunctions::rfts('/var/run/dmesg.boot', $buf)) {
                $parts = preg_split("/rebooting|Uptime/", $buf, -1, PREG_SPLIT_NO_EMPTY);
                $this->_dmesg = preg_split("/\n/", $parts[count($parts) - 1], -1, PREG_SPLIT_NO_EMPTY);
            }
        }
        return $this->_dmesg;
    }

    private function _ip()
    {
        if (USE_VHOST === true) {
            $this->sys->setIp(gethostbyname($this->_hostname()));
        } else {
            if (!($result = getenv('SERVER_ADDR'))) {
                $this->sys->setIp(gethostbyname($this->_hostname()));
            } else {
                $this->sys->setIp($result);
            }
        }
    }

    private function _kernel()
    {
        $s = $this->grabkey('kern.version');
        $a = preg_split('/:/', $s);
        $this->sys->setKernel($a[0].$a[1].':'.$a[2]);
    }

    private function _loadavg()
    {
        $s = $this->grabkey('vm.loadavg');
        $s = preg_replace('/{ /', '', $s);
        $s = preg_replace('/ }/', '', $s);
        $this->sys->setLoad($s);
    }

    private function _cpuinfo()
    {
        $cpunum = $this->grabkey('hw.ncpu');
        $cpumodel = $this->grabkey('hw.model');
        foreach ($this->readdmesg() as $line) {
            if (preg_match("/".$this->_CPURegExp1."/", $line, $ar_buf)) {
                break;
            }
        }
        $cpuinfo = array(
            'model'    => $cpumodel,
            'mhz'      => (null === $ar_buf) ? 'Unknow' : round($ar_buf[2]),
        );
        for($i=0; $i<$cpunum; $i++){
            $this->sys->setCpusInfo($cpuinfo);
        }
    }

    private function _memory()
    {
        $pagesize = $this->grabkey('hw.pagesize');

        if (CommonFunctions::executeProgram('vmstat', '', $vmstat)) {
            $lines = preg_split("/\n/", $vmstat, -1, PREG_SPLIT_NO_EMPTY);
            $ar_buf = preg_split("/\s+/", trim($lines[2]), 19);
            $this->sys->setMemFree($ar_buf[4] * $pagesize);
            $this->sys->setMemTotal($this->grabkey('hw.physmem'));
            $this->sys->setMemUsed($this->sys->getMemTotal() - $this->sys->getMemFree());
            
            if (CommonFunctions::executeProgram('swapinfo', '-k', $swapstat)) {
                $lines = preg_split("/\n/", $swapstat, -1, PREG_SPLIT_NO_EMPTY);
                foreach ($lines as $line) {
                    $ar_buf = preg_split("/\s+/", $line, 6);
                    if (($ar_buf[0] != 'Total') && ($ar_buf[0] != 'Device')) {
                        $this->sys->setSwapTotal($ar_buf[1] * 1024);
                        $this->sys->setSwapUsed($ar_buf[2] * 1024);
                    }
                }
            }
        }
    }

    private function _disk()
    {
        $arrResult = CommonFunctions::df("-P");
        foreach ($arrResult as $dev) {
            $this->sys->setFilesystems($dev);
        }
    }

    private function _network()
    {
        if (CommonFunctions::executeProgram('netstat', '-nibd | grep Link', $netstat)) {
            $lines = preg_split("/\n/", $netstat, -1, PREG_SPLIT_NO_EMPTY);
            foreach ($lines as $line) {
                $ar_buf = preg_split("/\s+/", $line);
                if (! empty($ar_buf[0])) {
                    $networkInfo = array();
                    $networkInfo['dev'] = $ar_buf[0];
                    if (strlen($ar_buf[3]) < 15) { /* Null Address */
                        if (isset($ar_buf[11])) {
                          $networkInfo['tx'] = $ar_buf[9];
                          $networkInfo['rx'] = $ar_buf[6];
                        } else {
                          $networkInfo['tx'] = $ar_buf[8];
                          $networkInfo['rx'] = $ar_buf[5];
                        }
                    } else { 
                        if (isset($ar_buf[12])) {
                          $networkInfo['tx'] = $ar_buf[10];
                          $networkInfo['rx'] = $ar_buf[7];
                        } else {
                          $networkInfo['tx'] = $ar_buf[9];
                          $networkInfo['rx'] = $ar_buf[6];
                        }  
                    }
                    $this->sys->setNetworkInfo($networkInfo);
                }
            }
        }
    }

    function build()
    {
        $this->_memory();
        $this->_disk();
        $this->_cpuinfo();
        $this->_kernel();
        $this->_loadavg();
        $this->_hostname();
        $this->_ip();
        $this->_network();
    }
}

class ServerInfo
{
    private $user = 'Unknown';
    private $documentRoot = '/srv/http';
    private $webserverVersion = 'Unknown';
    private $phpVersion = 'Unknown';
    private $mysqlVersion = 'Unknown';
    
    function __construct()
    {
        $this->build();
    }
    
    public function getUser()
    {
        return $this->user;
    }
    
    public function getDocumentRoot()
    {
        return $this->documentRoot;
    }
    
    public function getWebserverVersion()
    {
        return $this->webserverVersion;
    }
    
    public function getPhpVersion()
    {
        return $this->phpVersion;
    }
    
    public function getMysqlVersion()
    {
        return $this->mysqlVersion;
    }
    
    private function _setWebserverVersion()
    {
        $this->webserverVersion = $_SERVER['SERVER_SOFTWARE'];
        return $this->webserverVersion;
    }
    
    private function _setPhpVersion()
    {
        $this->phpVersion = 'php-'. PHP_VERSION;
        return $this->phpVersion;
    }
    
    private function _setMysqlVersion()
    {
        if(function_exists("mysql_get_server_info")) {
            $msv = mysql_get_server_info();
            $msv = $msv ? $msv : 'Unknown';
            $this->mysqlVersion = $msv;
        }
        return $this->mysqlVersion;
    }
    
    private function _setUser()
    {
        $this->user = get_current_user() ? get_current_user() : 'Unknown';
        return $this->user;
    }
    
    private function _setDocumentRoot()
    {
        $this->documentRoot = $_SERVER['DOCUMENT_ROOT'] ? 
            str_replace('\\','/',$_SERVER['DOCUMENT_ROOT']) : 
            str_replace('\\','/',dirname(__FILE__));
        return $this->documentRoot;
    }
    
    private function build()
    {
        $this->_setUser();
        $this->_setDocumentRoot();
        $this->_setMysqlVersion();
        $this->_setPhpVersion();
        $this->_setWebserverVersion();
    }
}

switch(PHP_OS) {
    case "Linux":
        $os = new LinuxOS();
        break;
    case "FreeBSD":
        $os = new FreeBSD();
        break;
    case "WINNT":
        $os = new WinNT();
        break;
    default:
        break;
}

if(!is_object($os)){
    exit("Sorry, this script does not support for this OS at this time.");
} else {
    $sys = $os->getSys();
    $si  = $os->getServerInfo();
}
?><!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
    <head>
        <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
        <title><?php echo $os->getServerInfo()->getUser().'@'.$os->getSys()->getHostname(); ?></title>
        <meta name="Author" content="infong" />
        <style type="text/css" rel="stylesheet" >
            body {color: #FFF;margin: 0;padding:0;background-color:#9099AE;font:14px/1.5 "微软雅黑",geneva,'Trebuchet MS', verdana, arial, sans-serif;background:#1269AC;}
            #wrapper {height: 500px;width: 840px;padding: 0 6px 6px 6px;border: 1px solid #666;border-radius: 6px;margin: 30px auto;box-shadow: 0 0 1px white inset,0 0 1px white inset, 0 0 4px #666;box-shadow: 0 0 10px #666;background: rgba(255, 255, 255, 0.6);overflow: hidden;}
            #title {text-align:center;height:35px;line-height:35px;font-size: 13px;font-weight: bold;color:#000;}
            #inwrapper {height: 463px; padding-left: 15px;min-height: 334px;overflow-y: scroll;border: 1px solid #666;background: #000;box-shadow: 0 0 1px #666 inset,0 0 2px white;}
            #inwrapper p {text-align: center;}
            #inwrapper p strong {font-size: 1.2em;}
            .command span {color: #0F0;}
        </style>
    </head>
    <body>
<div id="wrapper">
    <div id="title">
        <?php echo $os->getServerInfo()->getUser().'@'.$os->getSys()->getHostname(); ?>: <?php echo $os->getServerInfo()->getDocumentRoot();?>
    </div>
    <div id="inwrapper">
<pre class="command">
<span><?php echo $os->getServerInfo()->getUser().'@'.$os->getSys()->getHostname(); ?>:~$&gt; </span>cat systemtype
<?php echo $os->getSys()->getOSType() ?></pre>
<pre class="command">
<span><?php echo $os->getServerInfo()->getUser().'@'.$os->getSys()->getHostname(); ?>:~$&gt; </span>echo cpuinfo
<?php foreach($os->getSys()->getCpusInfo() as $id => $oneCpu): ?>
processor id   : <?php echo $id ?> 
model name     : <?php echo $oneCpu['model'] ?> 
CPU MHz        : <?php echo $oneCpu['mhz'] ?> 
cache size     : <?php echo $oneCpu['cache'] ?> 
bogomips size  : <?php echo $oneCpu['bogomips'] ?> 
<?php endforeach; ?>
</pre>
<pre class="command">
<span><?php echo $os->getServerInfo()->getUser().'@'.$os->getSys()->getHostname(); ?>:~$&gt; </span>cat kernelversion
<?php echo $os->getSys()->getKernel() ?></pre>
<pre class="command">
<span><?php echo $os->getServerInfo()->getUser().'@'.$os->getSys()->getHostname(); ?>:~$&gt; </span>date
<?php echo $os->getSys()->getTime(); ?></pre>
<pre class="command">
<span><?php echo $os->getServerInfo()->getUser().'@'.$os->getSys()->getHostname(); ?>:~$&gt; </span>uptime
up <?php echo CommonFunctions::formatUptime($os->getSys()->getUptime()) ?>,  load average: <?php echo $os->getSys()->getLoad(); ?></pre>
<pre class="command">
<span><?php echo $os->getServerInfo()->getUser().'@'.$os->getSys()->getHostname(); ?>:~$&gt; </span>df -h
Filesystem    Size       Used       Avail      Use%    Mountpoint
<?php foreach($os->getSys()->getFilesystems() as $fs): ?>
<?php printf("%-14s%-11s%-11s%-11s%-8s%s",
        $fs['name'],
        CommonFunctions::formatsize($fs['total'], TRUE),
        CommonFunctions::formatsize($fs['used'], TRUE),
        CommonFunctions::formatsize($fs['free'], TRUE),
        CommonFunctions::calPercent($fs['used'],$fs['total']).'%',
        $fs['mountpoint']
         ); ?> 
<?php endforeach; ?>
</pre>
<pre class="command">
<span><?php echo $os->getServerInfo()->getUser().'@'.$os->getSys()->getHostname(); ?>:~$&gt; </span>echo meminfo
            Total       Used       Free       Useage    Buffers   Cached
<?php printf("%-12s%-12s%-11s%-11s%-10s%-10s%s", "Mem ", 
            CommonFunctions::formatsize($os->getSys()->getMemTotal(), TRUE), 
            CommonFunctions::formatsize($os->getSys()->getMemUsed(), TRUE),
            CommonFunctions::formatsize($os->getSys()->getMemFree(), TRUE),
            $os->getSys()->getMemPercentUsed().'%', 
            CommonFunctions::formatsize($os->getSys()->getMemBuffer(), TRUE),
            CommonFunctions::formatsize($os->getSys()->getMemCache(), TRUE)); ?> 
<?php if(0 != $os->getSys()->getMemCache()):?>
<?php printf("%-24s%-11s%-11s%s%%", "-/+ buffers/cache ", 
            CommonFunctions::formatsize($os->getSys()->getMemRealUsed(), TRUE),
            CommonFunctions::formatsize($os->getSys()->getMemTotal() - $os->getSys()->getMemRealUsed(), TRUE),
            $os->getSys()->getMemPercentRealUsed()); ?> 
<?php endif;?>
<?php if(0 != $os->getSys()->getSwapTotal()):?>
<?php printf("%-12s%-12s%-11s%-11s%s%%", "Swap ", 
            CommonFunctions::formatsize($os->getSys()->getSwapTotal(), TRUE), 
            CommonFunctions::formatsize($os->getSys()->getSwapUsed(), TRUE),
            CommonFunctions::formatsize($os->getSys()->getSwapTotal() - $os->getSys()->getSwapUsed(), TRUE),
            $os->getSys()->getSwapPercentUsed()); ?> 
<?php endif;?>
</pre>
<pre class="command">
<span><?php echo $os->getServerInfo()->getUser().'@'.$os->getSys()->getHostname(); ?>:~$&gt; </span>echo webserverinfo
<?php echo $os->getServerInfo()->getWebserverVersion(); ?>
</pre>
<pre class="command">
<span><?php echo $os->getServerInfo()->getUser().'@'.$os->getSys()->getHostname(); ?>:~$&gt; </span>echo phpversion
<?php echo $os->getServerInfo()->getPhpVersion(); ?>
</pre>
<pre class="command">
<span><?php echo $os->getServerInfo()->getUser().'@'.$os->getSys()->getHostname(); ?>:~$&gt; </span>echo bandwidth
<?php foreach($os->getSys()->getNetworkInfo() as $dv => $networkInfo):?>
<?php printf("%-6s",$networkInfo['dev']); ?>: RX: <?php echo CommonFunctions::formatsize($networkInfo['rx'], TRUE)?> TX: <?php echo CommonFunctions::formatsize($networkInfo['tx'], TRUE)?> 
<?php endforeach;?>
</pre>
<pre class="command">
<span><?php echo $os->getServerInfo()->getUser().'@'.$os->getSys()->getHostname(); ?>:~$&gt; </span>echo scriptruninfo
page load in <?php echo round((CommonFunctions::microTimeFloat() - $time_start) * 1000, 3)?> ms, <?php echo CommonFunctions::memoryUsage(); ?> Used
</pre>
    </div>
</div>
</html>
